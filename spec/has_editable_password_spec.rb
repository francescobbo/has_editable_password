require 'spec_helper.rb'

describe HasEditablePassword do
  # Since this is an extension of has_secure_password ensure that all the
  # methods defined by has_secure_password are still there

  it 'has an #authenticate method' do
    expect(User.new.respond_to? :authenticate).to be_true
  end

  it 'has a #password= method' do
    expect(User.new).to respond_to :password=
  end

  it 'has a password_confirmation= method' do
    expect(User.new).to respond_to :password=
  end

  # Additional accessors for current password or password recovery token

  it 'has a #current_password= method' do
    expect(User.new).to respond_to :current_password=
  end

  it 'has a #recovery_token= method' do
    expect(User.new).to respond_to :recovery_token=
  end

  let(:user) { User.new }

  describe '#password=' do
    it 'sets the password_digest field to the hash of the password' do
      user.password = 'secret'
      expect(BCrypt::Password.new(user.password_digest)).to eq 'secret'
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
      it 'returns false if the token is a random string' do
        user.generate_recovery_token
        user.recovery_token = "deadbeef"
        expect(user.valid_recovery_token?).to be_false
      end

      context 'the token is a base64 string' do
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
  end
end
