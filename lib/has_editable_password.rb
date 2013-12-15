require 'active_support/concern'
require 'active_model/secure_password'
require 'securerandom'

##
# Just include this module into your model to have all of its nice features
# :)
module HasEditablePassword
  extend ActiveSupport::Concern
  include ActiveModel::SecurePassword

  included do
    has_secure_password

    attr_writer :current_password
    attr_writer :recovery_token

    validate :password_change, on: :update, if: :password_digest_changed?

    ##
    # Overrides the has_secure_password implementation to provide nice features:
    # * Password backup
    # * Password update timestamp
    def password=(value)
      @old_password_digest = password_digest unless @old_password_digest or password_digest.blank?
      changing_password
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
  # * +:length+ - this is the length of the SecureRandom string generated
  # as the token. Since the token is base64_encoded it will be longer than
  # that. Default is 32.
  # * +:save+ - you can use this if you don't want save to be called.
  #     generate_recovery_token(save: false)
  #
  def generate_recovery_token(options = {})
    token = SecureRandom.urlsafe_base64(options.delete(:length) || 32)
    self.password_recovery_token = BCrypt::Password.create(token)
    self.password_recovery_token_creation = Time.now
    save unless options.delete(:save) == false
    token
  end

  ##
  # Returns true if the +token+ matches with the stored one and the
  # token creation time is less than 24 hours ago
  #
  # If +token+ is +nil+, the stored token is compared with +@recovery_token+
  def valid_recovery_token?(token = nil)
    recovery_token_match?(token) and !recovery_token_expired?
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
  # True if the token has been updated more than 24 hours ago
  def recovery_token_expired?
    # 86400 = seconds in a day
    (Time.now - self.password_recovery_token_creation).round >= 86400
  end

  ##
  # Compares password_recovery_token with:
  # * @recovery_token if +token+ is nil
  # * +token+ otherwise
  #
  # True if password_recovery_token matches.
  # False if password_recovery_token is nil
  # False if @recovery_token (or +token+) do not match the stored token
  def recovery_token_match?(token = nil)
    BCrypt::Password.new(self.password_recovery_token) == (token || @recovery_token)
  rescue
    false
  end

  ##
  # True if a valid recovery token or current password have been set
  #
  def allow_password_change?
    valid_recovery_token? or current_password_match?
  end

  ##
  # Validation called on :update when the password_digest is touched.
  # Sets an error on password unless the current_password or a valid recovery_token is set
  def password_change
    errors[:password] << 'Unauthorized to change the password' unless allow_password_change?
  end

  def changing_password
    unless password_digest_changed?
      update_previous_digest
      update_digest_timestamp
    end
  end

  def update_previous_digest
    if respond_to?(:previous_password_digest=) and !password_digest.blank?
      self.previous_password_digest = password_digest
    end
  end

  def update_digest_timestamp
    if respond_to? :password_digest_updated=
      self.password_digest_updated = Time.now
    end
  end
end
