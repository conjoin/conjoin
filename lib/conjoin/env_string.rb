module Conjoin
  class EnvString < String
    [:production, :development, :test, :staging].each do |env|
      define_method "#{env}?" do
        self == env.to_s
      end
    end

    def mounted?
      defined?(::Rails) ? true : false
    end

    def console?
      ENV['CONJOIN_CONSOLE'] ? true : false
    end
  end
end
