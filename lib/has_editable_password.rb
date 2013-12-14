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

    validate :password_change, on: :update, if: :password_digest_changed?

    def password=(value)
      @old_password_digest = password_digest unless @old_password_digest or password_digest.blank?

      unless password_digest.blank? or password_digest_changed?
        self.previous_password_digest = password_digest if respond_to? :previous_password_digest=
        self.password_digest_updated = Time.now if respond_to? :password_digest_updated=
      end

      super(value)
    end
  end

  ##
  # Creates a new +password_recovery_token+
  #
  # If a token was already there it is discarded. Also sets
  # +password_recovery_token_creation+ to the current time.
  # Unless specified it calls +save+ to store the token in the database.
  #
  # options[:length] - this is the length of the SecureRandom string generated
  #   as the token. Since the token is base64_encoded it will be longer than
  #   that. Default is 32.
  # options[:save] - you can use this if you don't want save to be called.
  #   generate_recovery_token(save: false)
  #
  def generate_recovery_token(options = {})
    token = SecureRandom.urlsafe_base64(options.delete(:length) || 32)
    self.password_recovery_token = BCrypt::Password.create(token)
    self.password_recovery_token_creation = Time.now
    save unless options.delete(:save) == false
    token
  end

  ##
  # Returns true if the +recovery_token+ matches with the stored one and the
  # token creation time is less than 24 hours ago
  #
  def valid_recovery_token?
    recovery_token_match? and !recovery_token_expired?
  end

  ##
  # Returns true if +current_password+ matches the stored +password_digest+.
  #
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

  def allow_password_change?
    valid_recovery_token? or current_password_match?
  end

  def password_change
    errors[:password] << 'Unauthorized to change the password' unless allow_password_change?
  end
end
