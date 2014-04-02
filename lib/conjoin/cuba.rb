require "cuba"
require "cuba/render"

module Conjoin
  class Cuba < ::Cuba
    class << self
      def settings= settings
        @settings = settings
      end

      def root
        @root ||= Conjoin.root
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
        partial_template = template.gsub(/([a-zA-Z_]+)$/, '_\1')
        render(template_path(partial_template), locals, settings[:render][:options])
      end
    end
  end
end
