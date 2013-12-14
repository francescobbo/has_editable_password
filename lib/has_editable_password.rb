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

    def password=(value)
      @old_password_digest = self.password_digest unless @old_password_digest or self.password_digest.blank?
      super(value)
    end
  end

  def generate_recovery_token(options = {})
    token = SecureRandom.urlsafe_base64(options.delete(:length) || 32)
    self.password_recovery_token = BCrypt::Password.create(token)
    self.password_recovery_token_creation = Time.now
    save unless options.delete(:save) == false
    token
  end

  def valid_recovery_token?
    recovery_token_match? and !recovery_token_expired?
  end

  def current_password_match?
    if @current_password
      if @old_password_digest
        BCrypt::Password.new(@old_password_digest) == @current_password
      else
        # almost same as #authenticate (returns true instead of the object)
        BCrypt::Password.new(self.password_digest) == @current_password
      end
    else
      false
    end
  end

  private
  def recovery_token_expired?
    # 86400 = seconds in a day
    (Time.now - self.password_recovery_token_creation).round >= 86400
  end

  def recovery_token_match?
    BCrypt::Password.new(self.password_recovery_token) == @recovery_token
  rescue
    false
  end
end
