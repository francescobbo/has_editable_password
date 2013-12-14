has_editable_password
=====================

HasEditablePassword extends has_secure_password with updating capabilities. On password update, the old password or a recovery token is asked.

Usage
-----
Add to gemfile:

    gem 'has_secure_password'
    
Install:

    bundle install

With **ActiveRecord**:

Generate a migration:

    rails g migration add_password_fields_to_user password_digest:string password_recovery_token:string password_recovery_token_created:datetime

Migrate:

    rake db:migrate

Include:

    class User < ActiveRecord::Base
      include HasEditablePassword
    end
    
With **Mongoid**:

Include and add fields:

    class User
      include Mongoid::Document
      include HasEditablePassword
      
      field :password_digest, type: String
      field :password_recovery_token, type: String
      field :password_recovery_token_creation, type: DateTime
    end
