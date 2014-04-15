module Conjoin
  module Auth
    if Conjoin.env.mounted?
      require 'warden'
      require 'devise'
      include Devise::TestHelpers
    end

    class << self
      attr_accessor :app
    end

    def self.setup app
      self.app = app

      if not Conjoin.env.mounted?
        require 'shield'
        app.plugin Shield::Helpers
        app.use Shield::Middleware, "/login"
      end
    end

    def login_path
      req.env['REQUEST_URI'][/login/] ? true : false
    end

    def logout_path
      req.env['REQUEST_URI'][/logout/] ? true : false
    end

    def current_user
      if not Conjoin.env.mounted?
        authenticated(Subro::Models::User)
      else
        req.env['warden'].authenticate(scope: :user)
      end
    end

    def logged_in?
      current_user ? true : false
    end

    def sign_in *args
      if args.length > 1
        user, scope = args
      else
        scope = :user
        user  = args.first
      end

      if Auth.app.mounted?
        @request = req
        super scope, user
      else
        session.clear
        session['VendorWizard::User'] = user.id
      end
    end

    class Routes < Conjoin::Cuba
      plugin Auth

      define do
        on login_path do
          on get do
            user = UserLoginForm.new
            res.write view("login", user: user)
          end

          on post do
            user            = UserLoginForm.new
            user.attributes = req[:user_login]

            if user.valid_only?(:email, :password) && login(User, user.email, user.password)
              res.redirect req[:return] || '/'
            else
              user.password = nil
            end

            res.write view("login", user: user)
          end
        end

        on logout_path do
          logout User

          res.redirect '/'
        end
      end
    end
  end
end
