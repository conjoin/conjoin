module Conjoin
  module Assets
    class << self
      attr_accessor :app
    end

    def self.setup app
      self.app = app

      require 'mimemagic'
      require 'base64'
      require 'slim'
      require 'sass'
      require 'ostruct'

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
      case file[/(\.[^.]+)$/]
      when '.css', '.js'
        path = "#{plugin.settings[:path] || '/'}#{cache_string}assets/#{file}"
      else
        path = "#{plugin.settings[:path] || '/'}#{cache_string}assets/images/#{file}"
      end
      "http#{req.env['SERVER_PORT'] == '443' ? 's' : ''}://#{req.env['HTTP_HOST']}#{path}"
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

    def  links_for type, opts = {}
      method    = :link
      path      = :href
      extention = :css

      options = {
        'data-turbolinks-track' => true
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
          options[path] = asset_path "#{type}.#{extention}"
          send(method, options)
        else
          app.send(type).each do |asset|
            options[path] = asset_path asset.gsub(/\.coffee/, '.js').gsub(/\.scss/, '.css')
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
    end

    class Helpers
      def asset_path path
        app.root + '/app/assets/' + path
      end
    end

    class Routes < Struct.new(:settings)
      def app
        App.settings = settings
        App.root = Conjoin::Assets.app.root
        App.plugin Conjoin::Cuba::Render
        App.plugin Assets
        App
      end
    end

    # erb  = Tilt::ERBTemplate.new "#{Assets.app.root}/app/assets/#{file}.scss"
    # scss = Tilt::ScssTemplate.new{ erb.render(Helpers.new)  }

    # scss.render
    class App < Conjoin::Cuba
      def add_asset file, ext
        dir     = ''
        new_ext = false

        case ext
        when 'css'
          dir     = !file[/^bower/] ? 'stylesheets/' : ''
          new_ext = 'scss' if stylesheet_assets.include? file + '.scss'
        when 'js'
          dir     = !file[/^bower/] ? 'javascripts/' : ''
          new_ext = 'coffee' if javascript_assets.include? file + '.coffee' \
                             or javascript_head_assets.include? file + '.coffee'
        end

        if new_ext
          render "#{Assets.app.root}/app/assets/#{dir}#{file}.#{new_ext}"
        else
          File.read "#{Assets.app.root}/app/assets/#{dir}#{file}.#{ext}"
        end
      end

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
            res.write add_asset file, ext
          end
        end
      end
    end
  end
end
