has_editable_password
=====================

HasEditablePassword extends has_secure_password with updating capabilities. On password update, the old password or a recovery token is asked.

Installation
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

Usage
-----

Now you have an has_secure_password equivalent. It works just like that.

To update the password, given the old one:

    class UserController
      def update
        @user = User.find(params[:id])
        if @user.update_attributes(params.require(:user).permit(:current_password, :password, :password_confirmation))
          render :show
        else
          # password didn't match OR current_password didn't match
          render :edit
        end
      end
    end
    
When submitting a password recovery form:

    class PasswordRecoveryController
      def create
        @user = User.find_by_email(params[:email])
          
        token = @user.generate_recovery_token
        url = edit_password_recovery_url(@user, token: token)
          
        # send url by email
        # render "An email has been sent with a link
      end
        
      # Accessed by email link
      def edit
        @user = User.find(params[:id])
        @user.recovery_token = params[:token]
          
        if @user.valid_recovery_token?
          render :show
        else
          flash[:error] = "Invalid token"
          redirect_to root_path
        end
      end
       
      def update
        @user = User.find(params[:id])
        @user.recovery_token = params[:token]
        
        if @user.update_attributes(params.require(:user).permit(:password, :password_confirmation)
          # login
          flash[:notice] = "Success"
          redirect_to root_path
        else
          # Invalid token or password did not match
          redirect_to root_path
        end
      end
    end

Old password backup
-------------------

If you want to keep a backup of the previous password (only the last one), just add another attribute:

    rails g migration add previous_password_digest:string

or

    field :previous_password_digest, type: String

You can use this for reminders or security alerts (the user using an old password is probably a malicious user with a
stolen password).

Last password change timestamp
------------------------------

If you need password change timestamp add the following attribute:

    rails g migration add password_digest_updated:date

or

    field :password_digest_updated, type: DateTime

This could be used for password expiration mechanisms or in combination with the backup to tell the user (or attacker):

    Man, you don't use that password anymore! You changed it a month ago!

