require 'mimemagic'
require 'base64'
require 'slim'
require 'sass'
require 'ostruct'
require 'stylus'
require 'stylus/tilt/stylus'
require 'slim'
require "tilt/coffee"
# require "tilt/sass"

module Conjoin
  module Assets
    class << self
      attr_accessor :app
    end

    def self.setup app
      self.app = app

      # if ENV['RACK_ENV'] != 'production'
      #   require 'rugged'
      # end

      Slim::Engine.set_default_options \
        disable_escape: true,
        use_html_safe: true,
        disable_capture: false,
        pretty: (Conjoin.env.production? or Conjoin.env.staging?) ? false : true

      app.settings[:assets] ||= OpenStruct.new({
        settings: {},
        stylesheet: [],
        images: [],
        javascript_head: [],
        javascript: []
      })
    end

    %w(stylesheet javascript javascript_head).each do |type|
      define_method "#{type}_assets" do
        plugin[:"#{type}"]
      end
    end

    def asset_path file
      if Conjoin.env.production? or Conjoin.env.staging?
        path = "#{plugin.settings[:path] || '/'}public/assets/#{file}"
      else
        case file[/(\.[^.]+)$/]
        when '.css', '.js'
          path = "#{plugin.settings[:path] || '/'}#{cache_string}assets/#{file}"
        else
          path = "#{plugin.settings[:path] || '/'}#{cache_string}assets/images/#{file}"
        end
      end
      "http#{(Conjoin.env.production? or Conjoin.env.staging?)? 's' : ''}://#{req.env['HTTP_HOST']}#{path}"
    end

    def image_tag file, options = {}
      options[:src] = asset_path(file)
      mab do
        img options
      end
    end

    def fa_icon icon, options = {}
      options[:class] ||= ''
      options[:class] += " fa fa-#{icon}"

      mab do
        i options
      end
    end

    def accepted_assets
      "(.*)\.(js|css|eot|svg|ttf|woff|png|gif|jpg|jpeg)$"
    end

    private

    def cache_string
      if Conjoin.env.mounted?
        # @cache_string ||= (File.read "#{Assets.app.root}/sha") + "/"
        "/"
      end
    end

    def plugin
      Assets.app.settings[:assets]
    end

    def links_for type, opts = {}
      method    = :link
      path      = :href
      extention = :css

      options = {
        'data-turbolinks-track' => 'true'
      }

      case type
      when :stylesheet_assets
        options.merge!({
          rel: 'stylesheet',
          type: 'text/css',
          media: 'all'
        })
      when :javascript_assets, :javascript_head_assets
        method    = :script
        path      = :src
        extention = :js
      else
        raise 'Please choose a type: stylesheet_assets, javascript_head_assets or javascript_assets'
      end

      # merge in the user options allowing them to override
      options.merge! opts

      app = self

      mab do
        if Conjoin.env.production? or Conjoin.env.staging?
          Thread.current[:sha] ||= File.read "#{Assets.app.root}/sha"
          case type
          when :stylesheet_assets
            name = 'stylesheet'
          when :javascript_assets
            name = 'javascript'
          end
          options[path] = asset_path "#{name}-#{Thread.current[:sha]}.#{extention}"
          send(method, options)
        else
          app.send(type).each do |asset|
            options[path] = asset_path asset.gsub(/\.coffee/, '.js').gsub(/\.(scss|styl)/, '.css')
            send(method, options)
          end
        end
      end
    end

    module ClassMethods
      %w(stylesheet javascript javascript_head).each do |type|
        define_method "#{type}_assets" do |files|
          files.each do |path|
            settings[:assets][:"#{type}"] << path
          end
        end
      end

      def all_assets
        settings[:assets]
      end

      def assets_settings as
        settings[:assets].settings.merge! as
      end

      def add_asset app, file, ext
        dir     = ''
        new_ext = false

        case file
        when /^bower/
          dir = 'assets/'
        when /^widgets/
          dir = '/'
        else
          case ext
          when 'js'
            dir = 'assets/javascripts/'
          when 'css'
            dir = 'assets/stylesheets/'
          else
            dir = 'assets/'
          end
        end

        case ext
        when 'css'
          %w(scss styl).each do |type|
            new_ext = type if app.settings[:assets]['stylesheet'].include? file + ".#{type}"
          end
        when 'js'
          new_ext = 'coffee' if app.settings[:assets]['javascript'].include? file + '.coffee' \
                             or app.settings[:assets]['javascript_head'].include? file + '.coffee'
        end

        if new_ext
          app.render "#{Assets.app.root}/app/#{dir}#{file}.#{new_ext}"
        else
          File.read "#{Assets.app.root}/app/#{dir}#{file}.#{ext}"
        end
      end
    end
    extend ClassMethods

    class Helpers
      def asset_path path
        app.root + '/app/assets/' + path
      end
    end

    class Routes < Struct.new(:settings)
      def app
        App.settings = settings
        App.root = settings[:root]
        App.plugin Conjoin::Cuba::Render
        App.plugin Assets
        App
      end
    end

    # erb  = Tilt::ERBTemplate.new "#{Assets.app.root}/app/assets/#{file}.scss"
    # scss = Tilt::ScssTemplate.new{ erb.render(Helpers.new)  }

    # scss.render
    class App < Conjoin::Cuba
      define do
        on get, accepted_assets do |file, ext|
          res.headers["Content-Type"] = "#{MimeMagic.by_extension(ext).to_s}; charset=utf-8"

          if %w(stylesheet_assets javascript_head_assets javascript_assets).include? file
            content = ''

            send(file).each do |asset|
              content += add_asset asset.sub(/(\.)(?!.*\.).+/, ""), ext
            end

            res.write content
          else
            res.write Assets.add_asset(self, file, ext)
          end
        end
      end
    end
  end
end
