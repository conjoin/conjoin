module Conjoin
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    attr_accessor :root

    def mount_root; @mount_root ||= Conjoin.env.mounted?? Rails.root : '../../'; end
    def root; Conjoin.env.mounted?? "#{Rails.root}/mounts/#{self.to_s.gsub('::App', '').underscore}" : Dir.pwd; end

    def env
      @env ||= EnvString.new(
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      )
    end

    def initialize!
      # Initializers
      Dir["#{root}/config/initializers/**/*.rb"].each  { |rb| require rb  }

      # Permissions
      Dir["#{root}/app/models/permissions/**/*.rb"].each {|rb| require rb }
      Dir["#{root}/app/permissions/**/*.rb"].each {|rb| require rb }

      # Models
      Dir["#{root}/app/models/*/*.rb"].each {|rb| require rb }
      Dir["#{root}/app/models/**/*.rb"].each {|rb| require rb }

      # Forms
      Dir["#{root}/app/forms/*/*.rb"].each {|rb| require rb }
      Dir["#{root}/app/forms/**/*.rb"].each {|rb| require rb }

      # Assets
      require "#{root}/config/assets"

      # Presenters
      Dir["#{root}/app/presenters/**/*.rb"].each  { |rb| require rb  }

      # Mailers
      Dir["#{root}/app/mailers/**/*.rb"].each  { |rb| require rb  }

      # Routes
      Dir["#{root}/app/routes/**/*.rb"].each  { |rb| require rb  }
      require "#{root}/config/routes"
    end
  end
end
