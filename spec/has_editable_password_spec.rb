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
end
