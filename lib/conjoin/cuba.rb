require "cuba"
require "cuba/render"

module Conjoin
  class Cuba < ::Cuba
    class << self
      def settings= settings
        @settings = settings
      end

      def root; @root ||= Dir.pwd; end
      def root= root
        @root = root
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

    module Render
      include ::Cuba::Render

      def self.setup(app)
        app.settings[:render] ||= {}
        app.settings[:render][:template_engine] ||= "slim"
        app.settings[:render][:layout] ||= "layouts/app"
        app.settings[:render][:views] ||= "#{app.root}/app/views"
        app.settings[:render][:options] ||= {
          default_encoding: Encoding.default_external
        }
      end

      alias original_partial partial

      def view(template, locals = {}, layout = settings[:render][:layout])
        original_partial(layout, { content: original_partial(template, locals) }.merge(locals))
      end

      def partial template, locals = {}
        partial_template = template.to_s.gsub(/([a-zA-Z_]+)$/, '_\1')
        render(template_path(partial_template), locals, settings[:render][:options])
      end
    end
  end
end
