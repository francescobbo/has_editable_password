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

  describe '#password=' do
    it 'sets the password_digest field to the hash of the password' do
      user = User.new
      user.password = 'secret'
      expect(BCrypt::Password.new(user.password_digest)).to eq 'secret'
    end
  end

  describe '#generate_recovery_token' do
    it 'returns a url-safe base64 string' do
      token = User.new.generate_recovery_token
      expect(token).to match(/^[a-z0-9\-_]+=*$/i)
    end

    it 'returns a 43 bytes token unless specified' do
      token = User.new.generate_recovery_token
      expect(token.size).to eq 43
    end

    it 'returns token larger than specified size' do
      token = User.new.generate_recovery_token length: 100
      token.size.should be >= 100
    end

    it 'sets the password_recovery_token attribute with the hash of the token' do
      user = User.new
      token = user.generate_recovery_token
      expect(BCrypt::Password.new(user.password_recovery_token)).to eq token
    end

    it 'sets the password_recovery_token_creation to Time.now' do
      user = User.new
      user.generate_recovery_token
      expect(user.password_recovery_token_creation.round).to eq Time.now.round
    end

    it 'calls #save unless specified' do
      user = User.new
      expect(user).to receive(:save)
      user.generate_recovery_token
    end

    it 'does not call #save if specified' do
      user = User.new
      expect(user).to_not receive(:save)
      user.generate_recovery_token(save: false)
    end
  end
end
