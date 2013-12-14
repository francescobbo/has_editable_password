$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'has_editable_password.rb'
require 'active_model'
require 'bcrypt'

# Mock an ActiveRecord-like class.
# Not using ActiveRecord because we want this to be ORM-agnostic
class User
  extend ActiveModel::Callbacks
  define_model_callbacks :initialize, :find, :touch, :only => :after
  define_model_callbacks :save, :create, :update, :destroy

  include ActiveModel::Validations
  include ActiveModel::Validations::HelperMethods
  include HasEditablePassword

  # we expect the user to define the password_digest field
  attr_accessor :password_digest
  attr_accessor :password_recovery_token
  attr_accessor :password_recovery_token_creation

  def initialize(hash = {})
    hash.each do |k, v|
      send("#{k}=", v)
    end
  end

  def save
  end
end
