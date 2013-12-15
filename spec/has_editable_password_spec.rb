require 'spec_helper.rb'

describe HasEditablePassword do
  let(:user) { User.new(password: 'secret', password_confirmation: 'secret') }

  # Since this is an extension of has_secure_password ensure that all the
  # methods defined by has_secure_password are still there

  it 'has an #authenticate method' do
    expect(user).to respond_to :authenticate
  end

  it 'has a #password= method' do
    expect(user).to respond_to :password=
  end

  it 'has a password_confirmation= method' do
    expect(user).to respond_to :password=
  end

  # Additional accessors for current password or password recovery token

  it 'has a #current_password= method' do
    expect(user).to respond_to :current_password=
  end

  it 'has a #recovery_token= method' do
    expect(user).to respond_to :recovery_token=
  end

  describe '#password=' do
    it 'sets the password_digest field to the hash of the password' do
      user.password = 'secret'
      expect(BCrypt::Password.new(user.password_digest)).to eq 'secret'
    end

    context 'previous_password_digest= exists' do
      it 'sets the previous_password_digest field' do
        expect(user).to receive :previous_password_digest=
        user.password = 'new_secret'
      end
    end

    context 'previous_password_digest= does not exist' do
      before { user.stub(:respond_to?).and_return false }

      it 'does not set the previous_password_digest field' do
        expect(user).to_not receive :previous_password_digest=
        user.password = 'new_secret'
      end
    end

    context 'password_digest_updated= exists' do
      it 'sets password_digest_updated on create too' do
        expect(user.password_digest_updated).to_not be_nil
      end

      it 'sets the password_digest_updated field' do
        expect(user).to receive(:password_digest_updated=)
        user.password = 'new_secret'
      end
    end

    context 'password_digest_updated= does not exist' do
      before { user.stub(:respond_to?).and_return false }

      it 'does not set the password_digest_updated field' do
        expect(user).to_not receive(:password_digest_updated=)
        user.password = 'new_secret'
      end
    end

    it 'only updates the previous_password and password_updated fields once' do
      user.password = 'new_secret'
      user.stub(:password_digest_changed?).and_return true
      user.password = 'banana'

      # Twice just to improve comprension
      expect(BCrypt::Password.new(user.previous_password_digest)).to_not eq 'new_secret'
      expect(BCrypt::Password.new(user.previous_password_digest)).to eq 'secret'
    end
  end

  describe '#generate_recovery_token' do
    it 'returns a url-safe base64 string' do
      token = user.generate_recovery_token
      expect(token).to match(/^[a-z0-9\-_]+=*$/i)
    end

    it 'returns a 43 bytes token unless specified' do
      token = user.generate_recovery_token
      expect(token.size).to eq 43
    end

    it 'returns token larger than specified size' do
      token = user.generate_recovery_token length: 100
      token.size.should be >= 100
    end

    it 'sets the password_recovery_token attribute with the hash of the token' do
      token = user.generate_recovery_token
      expect(BCrypt::Password.new(user.password_recovery_token)).to eq token
    end

    it 'sets the password_recovery_token_creation to Time.now' do
      user.generate_recovery_token
      expect(user.password_recovery_token_creation.round).to eq Time.now.round
    end

    it 'calls #save unless specified' do
      expect(user).to receive(:save)
      user.generate_recovery_token
    end

    it 'does not call #save if specified' do
      expect(user).to_not receive(:save)
      user.generate_recovery_token(save: false)
    end
  end

  describe '#valid_recovery_token?' do
    context 'a token was never generated' do
      it 'returns false' do
        user.recovery_token = "deadbeef"
        expect(user.valid_recovery_token?).to be_false
      end
    end

    context 'the creation is more than 24 hours ago' do
      it 'returns false' do
        token = user.generate_recovery_token
        user.password_recovery_token_creation = Time.now - 86401
        user.recovery_token = token  # Even if the token is correct
        expect(user.valid_recovery_token?).to be_false
      end
    end

    context 'the creation is less than 24 hours ago' do
      context 'the argument is nil' do
        it 'returns false if the stored token is a random string' do
          user.generate_recovery_token
          user.recovery_token = "deadbeef"
          expect(user.valid_recovery_token?).to be_false
        end

        context 'the stored token is a base64 string' do
          it 'returns false if the token does not match' do
            user.generate_recovery_token
            user.recovery_token = SecureRandom.urlsafe_base64
            expect(user.valid_recovery_token?).to be_false
          end

          it 'returns true if the token matches' do
            token = user.generate_recovery_token
            user.recovery_token = token
            expect(user.valid_recovery_token?).to be_true
          end
        end
      end

      context 'the argument is not nil' do
        it 'returns false if the token does not match' do
          user.generate_recovery_token
          expect(user.valid_recovery_token?(SecureRandom.urlsafe_base64)).to be_false
        end

        it 'returns true if the token matches' do
          token = user.generate_recovery_token
          expect(user.valid_recovery_token?(token)).to be_true
        end
      end
    end
  end

  describe '#current_password_match?' do
    context 'current_password is not been set' do
      it 'returns false' do
        expect(user.current_password_match?).to be_false
      end
    end

    context 'current_password is set' do
      context 'current_password does not match' do
        before { user.current_password = 's3cret' }

        it 'returns false' do
          expect(user.current_password_match?).to be_false
        end
      end

      context 'current_password does match' do
        before { user.current_password = 'secret' }

        it 'returns true' do
          expect(user.current_password_match?).to be_true
        end
      end

      context 'password_digest has been modified' do
        before { user.password = 'new_secret' }

        context 'current_password is set to the previous password' do
          before { user.current_password = 'secret' }

          it 'returns true' do
            expect(user.current_password_match?).to be_true
          end
        end

        context 'current_password is set to the new password' do
          before { user.current_password = 'new_secret' }

          it 'returns true' do
            expect(user.current_password_match?).to be_false
          end
        end
      end
    end
  end

  describe 'password editing validation' do
    let(:user) { User.new(password: 'banana', password_confirmation: 'banana') }

    context 'on create' do
      it 'is valid' do
        expect(user.valid?).to be_true
      end
    end

    context 'on update' do
      context 'password_digest was not touched' do
        before { user.stub(:password_digest_changed?).and_return false }

        it 'is valid' do
          expect(user.valid?(:update)).to be_true
        end
      end

      context 'password_digest was modified' do
        before { user.stub(:password_digest_changed?).and_return true }

        context 'a valid token is set' do
          let(:token) { user.generate_recovery_token }

          it 'is valid' do
            user.recovery_token = token
            expect(user.valid?(:update)).to be_true
          end
        end

        context 'an invalid valid token is set' do
          let(:token) do
            user.generate_recovery_token
            "deadbeef"
          end

          it 'is not valid' do
            user.recovery_token = token
            expect(user.valid?(:update)).to be_false
          end
        end

        context 'the current_password is valid' do
          it 'is valid' do
            user.current_password = 'banana'
            expect(user.valid?(:update)).to be_true
          end
        end

        context 'the current_password is invalid' do
          it 'is valid' do
            user.current_password = 'b4n4n4'
            expect(user.valid?(:update)).to be_false
          end
        end

        context 'neither is set' do
          it 'is not valid' do
            expect(user.valid?(:update)).to be_false
          end
        end
      end
    end
  end
end
