require 'active_support/concern'
require 'active_model/secure_password'
require 'securerandom'

module HasEditablePassword
  extend ActiveSupport::Concern
  include ActiveModel::SecurePassword

  included do
    has_secure_password

    attr_writer :current_password
    attr_writer :recovery_token
  end

  def generate_recovery_token(options = {})
    token = SecureRandom.urlsafe_base64(options.delete(:length) || 32)
    self.password_recovery_token = BCrypt::Password.create(token)
    self.password_recovery_token_creation = Time.now
    save unless options.delete(:save) == false
    token
  end
end
