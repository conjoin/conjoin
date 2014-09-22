require "encryptor"

module Conjoin
  module AuthToken
    def self.settings= s
      @settings = s
    end

    def self.settings
      @settings
    end

    def self.encrypt auth_token, iv=nil, salt=nil
      auth_token = auth_token.to_json

      if iv.present?
        encrypted = Encryptor.encrypt auth_token, key: AuthToken.settings.key, iv: iv,
                    salt: salt
      else
        encrypted = Encryptor.encrypt auth_token, key: AuthToken.settings.key
      end

      Base64.encode64(encrypted).strip
    end

    def self.decrypt auth_token, iv=nil, salt=nil
      if iv.present?
        decrypted = Encryptor.decrypt Base64.decode64(auth_token), key: AuthToken.settings.key, iv: iv,
                    salt: salt
      else
        decrypted = Encryptor.decrypt Base64.decode64(auth_token), key: AuthToken.settings.key
      end

      JSON.parse decrypted
    end

    class Middleware
      def initialize(app, settings = {})
        @app = app
        AuthToken.settings = OpenStruct.new settings
      end

      def call(env)
        responder = Responder.new(@app, env)
        responder.respond
      end

      class Responder
        def initialize(app, env)
          @app      = app
          @env      = env
        end

        def respond
          if req.params['auth_token'] and (auth_token = req.params['auth_token']) and\
             req.params['iv'] and (iv = Base64.decode64(req.params['iv']))

            salt = Base64.decode64(req.params['salt']) if req.params['salt']
            salt ||= nil

            obj = AuthToken.decrypt auth_token, iv, salt

            if Time.now < Time.parse(obj['expires_at'])
              user = AuthToken.settings.klass.constantize.find_by_username obj['username']
              case AuthToken.settings.type.to_sym
              when :warden
                req.env['warden'].set_user(user, scope: :user) if user
              when :shield
                req.session.clear
                req.session[AuthToken.settings.klass] = user.id if user
              end
            end
          end

          res.finish
        end

        private

        def return_signature
          s3 = S3Signature.new policy_data
          res.status = 200
          res.headers["Content-Type"] = 'application/json; charset=UTF-8'
          res.write({
            policy: s3.policy,
            signature: s3.signature
          }.to_json)
        end

        def path
          @env['PATH_INFO']
        end

        def req
          @req ||= Rack::Request.new(@env)
        end

        def res
          @res ||= begin
            status, headers, body = @app.call(req.env)
            Rack::Response.new(body, status, headers)
          end
        end
      end
    end
  end
end
