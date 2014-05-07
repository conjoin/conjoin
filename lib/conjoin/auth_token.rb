require "encryptor"

module Conjoin
  module AuthToken
    def self.settings= s
      @settings = s
    end

    def self.settings
      @settings
    end

    def self.encrypt auth_token
      auth_token = auth_token.to_json

      Base64.encode64(Encryptor.encrypt auth_token, key: AuthToken.settings.key, salt: begin
        "%AuthToken%#{AuthToken.settings.salt}%#{auth_token}%Salt%"
      end).strip
    end

    def self.decrypt auth_token
      JSON.parse Encryptor.decrypt(Base64.decode64(auth_token), key: AuthToken.settings.key, salt: begin
        "%AuthToken%#{AuthToken.settings.salt}%#{auth_token}%Salt%"
      end)
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
          if auth_token = req.params['auth_token']
            obj = AuthToken.decrypt auth_token

            if Time.now < Time.parse(obj['expires_at'])
              user = AuthToken.settings.klass.constantize.find obj['id']
              case AuthToken.settings.type.to_sym
              when :warden
                req.env['warden'].set_user(user, scope: :user)
              when :shield
                req.session.clear
                req.session[AuthToken.settings.klass] = obj['id']
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
