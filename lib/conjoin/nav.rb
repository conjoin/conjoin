require 'uri'

module Conjoin
  module Nav
    def self.setup app
      @settings = OpenStruct.new({
        navs: OpenStruct.new,
        icon_class: 'fa fa',
        active_class: 'active open'
      })
      require "#{app.root}/config/nav.rb"
    end

    def self.settings
      @settings
    end

    def self.config &block
      Config.new(block, self).run
    end

    def nav name, &block
      Config.new(block, self).load_nav name
    end

    class Config < Struct.new(:block, :app)
      def run
        self.instance_eval(&block)
      end

      def nav name, links
        config.navs[name] ||= []
        config.navs[name].concat links
      end

      def load_nav name
        if links = config.navs[name]
          loaded_links = load_links links
        else
          raise "There isn't a nav called: #{name}"
        end

        block.call loaded_links
      end

      def load_links links
        loaded_links = []

        links.each do |link|
          link = OpenStruct.new(link)

          if !link.if or app.instance_exec(&link.if)
            link.icon         = config.icon_class + '-' + link.icon if link.icon
            link.active       = URI.decode(app.req.env['REQUEST_URI'])[link.path]
            link.active_class = link.active ? config.active_class : false
            link.id           = "nav-#{link.text.underscore}"
            link.label        = app.instance_exec(&link.label) if link.label

            if link.subs
              link.subs = load_links link.subs
            end

            if link.active_class or !link.hidden
              loaded_links << link
            end
          end
        end

        loaded_links
      end

      def config
        Conjoin::Nav.settings
      end
    end
  end
end
