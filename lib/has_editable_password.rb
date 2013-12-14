require 'active_support/concern'
require 'active_model/secure_password'

module HasEditablePassword
  extend ActiveSupport::Concern
  include ActiveModel::SecurePassword

  included do
    has_secure_password

    attr_writer :current_password
    attr_writer :recovery_token
  end
end
