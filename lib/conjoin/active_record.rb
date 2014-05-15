require 'active_record'
require 'enumerize'
require 'protector'
require 'mini_record'
Protector::Adapters::ActiveRecord.activate!

module Conjoin
  module ActiveRecord
    include ::ActiveRecord

    class << self
      attr_accessor :app
    end

    def self.setup app
      self.app = app
      ActiveRecord::Base.send :include, Form

      if not Conjoin.env.mounted?
        start_active_record
        ActiveRecord::Base.default_timezone = Time.zone
      end
    end

    private

    def self.start_active_record
      if not Conjoin.env.test?
        return if ActiveRecord::Base.connected?
      else
        if ActiveRecord::Base.connected?
          ActiveRecord::Base.connection.disconnect!
        end
      end
      # ActiveRecord::Base.logger = Logger.new(STDERR) unless @app.test?

      db = URI.parse ENV['DATABASE_URL']

      ActiveRecord::Base.establish_connection(
          adapter: db.scheme == 'postgres' ? 'postgresql' : db.scheme,
          encoding: 'utf8',
          reconnect: true,
          database: db.path[1..-1],
          host: db.host,
          port: db.port,
          pool: ENV['DATABASE_POOL'] || 5,
          username: db.user,
          password: db.password,
          wait_timeout: 2147483
      )
    end

    module Form
      extend ActiveSupport::Concern

      attr_accessor :req_params

      included do
        define_model_callbacks :validates, :save_as
        before_save :save_unrestricted_attributes
      end

      def is_form?
        self.class.model_name.to_s[/Form$/]
      end

      def validate
      end

      def validates req_params, opts = {}
        req_params = req_params.is_a?(OpenStruct) ? req_params.to_hash : HashIndifferent.new(req_params)
        @req_params = req_params

        if as = opts.delete(:as)
          add_creator_and_updater_for self, as, req_params
        end

        run_callbacks :validates do
          self.attributes = req_params
          valid?
        end
      end

      def save_as current_user
        run_callbacks :save_as do
          add_creator_and_updater_for self, current_user, req_params
          save!
        end
      end

      def save_unrestricted_attributes
        if @unrestricted_attributes and @unrestricted_attributes.any?
          @unrestricted_attributes.each do |field, value|
            self.send "#{field}=", value
          end
        end
      end

      def set_unrestricted_attribute field, value
        @unrestricted_attributes ||= {}
        @unrestricted_attributes[field] = value
      end

      def set_unrestricted_attributes *fields
        fields.extract_options!.each do |field, value|
          set_unrestricted_attribute field, value
        end
      end

      def add_creator_and_updater_for(model, current_user = nil, current_params)
        # set the creator and updater
        id = current_user.try(:id) || ENV["SYSTEM_USER_ID"]

        # Save creator
        if model.respond_to? :creator_id and model.new_record?
          model.set_unrestricted_attribute 'creator_id', id
        end

        # Save updater
        if model.respond_to? :updater_id
          model.set_unrestricted_attribute 'updater_id', id
        end

        return unless current_params
        # loop through associated records
        current_params.each do |name, value|
          if name.end_with?("_attributes")
            associated_name  = name.gsub(/_attributes$/, '')
            associated_model = model.try associated_name

            if associated_model.kind_of? ::ActiveRecord::Base
              new_current_params = current_params[name]
              if new_current_params.kind_of? Hash
                add_creator_and_updater_for associated_model, current_user, new_current_params
              end
            elsif associated_model.kind_of? ActiveRecord::Associations::CollectionProxy
              new_current_params = current_params[name]
              associated_model.each_with_index do |current_model, i|
                add_creator_and_updater_for current_model, current_user, new_current_params[i]
              end
            end
          end
        end
      end

      def remove_error!(attribute, message = :invalid, options = {})
        # -- Same code as private method ActiveModel::Errors.normalize_message(attribute, message, options).
        callbacks_options = [:if, :unless, :on, :allow_nil, :allow_blank, :strict]
        case message
        when Symbol
          message = self.errors.generate_message(attribute, message, options.except(*callbacks_options))
        when Proc
          message = message.call
        else
          message = message
        end
        # -- end block

        # -- Delete message - based on ActiveModel::Errors.added?(attribute, message = :invalid, options = {}).
        message = self.errors[attribute].delete(message) rescue nil
        # -- Delete attribute from errors if message array is empty.
        self.errors.messages.delete(attribute) if !self.errors.messages[attribute].present?
        return message
      end

      def valid_except?(except={})
        self.valid?
        # -- Use this to call valid? for superclass if self.valid? is overridden.
        # self.class.superclass.instance_method(:valid?).bind(self).call
        except.each do |attribute, message|
          if message.present?
            remove_error!(attribute, message)
          else
            self.errors.delete(attribute)
          end
        end
        !self.errors.present?
      end

      def valid_only? *columns
        self.valid?
        self.errors.messages.each do |field, message|
          self.errors.delete(field) unless columns.include? field
        end
        !self.errors.present?
      end
    end
  end
end
