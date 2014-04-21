require "rack/csrf"

module Conjoin
  module FormBuilder
    INPUTS = [
      :boolean , :checkbox , :date  , :decimal , :file  , :hidden ,
      :integer , :password , :radio , :select  , :state , :string ,
      :display , :datetime , :time  , :year    , :text
    ]

    def self.setup app
      require 'conjoin/mab'

      app.use Rack::Csrf
      app.plugin Conjoin::Csrf
      # Dir["#{File.dirname(__FILE__)}/plugin/inputs/**/*.rb"].each  { |rb| require rb  }
      INPUTS.each do |input|
        require_relative "inputs/#{input}"
      end

      Dir["#{app.root}/app/inputs/**/*.rb"].each  { |rb| require rb  }
    end

    def form_for record, options = {}, &block
      raise ArgumentError, "Missing block" unless block_given?

      if as = options.delete(:as)
        model_name = as
      elsif record.is_form?
        model_name = record.class.model_name.to_s.gsub(/\w+::/, '').gsub(/Form$/, '').underscore
      else
        model_name = record.class.model_name.singular
      end

      fields = Fields.new self, [model_name], record, block

      form_options = {
        class: 'form-horizontal',
        role: 'form',
        method: 'post',
        novalidate: 'true',
        remote: true,
        action: options.delete(:url) || "/" + record.class.model_name.plural
      }.merge! options

      if form_options.delete(:remote)
        form_options['data-remote'] = 'true'
      end

      mab do
        form form_options do
          input type: 'hidden', name: '_method', value: (record.id ? 'patch' : 'post')
          text! csrf_tag
          text! fields.render
        end
      end
    end

    class Fields < Struct.new(:app, :models, :record, :block, :index)
      def render
        html = block.call(self, index)
        names = [].concat models
        names << 'id'

        mab do
          if record.id
            input type: 'hidden', name: nested_names_for(names), value: record.id
          end
          text! html
        end
      end

      def submit options = {}
        mab do
          input type: 'submit',
            value: options[:value] || 'Submit',
            class: 'btn'
        end
      end

      def nested_names_for names
        # create field names that map to the correct models
        names.each_with_index.map do |field, i|
          i != 0 ? "[#{field}]" : field
        end.join
      end

      def association field_name, options = {}
        options[:is_association] = true
        input field_name, options
      end

      def input_field field_name, options = {}
        options[:wrapper] = false
        input field_name, options
      end

      def input field_name, options = {}
        names = [].concat models
        if options.delete(:is_association)
          names << "#{field_name.to_s.singularize}_ids"
          names << ''
        else
          names << field_name
        end

        # create field names that map to the correct models
        nested_name = nested_names_for names

        record_class = record.class.model_name.name.constantize

        if as = options.delete(:as)
          record_type = as.to_s.classify
        elsif record_class.mini_record_columns \
          and mini_column = record_class.mini_record_columns[field_name] \
          and input_as = mini_column[:input_as]
            record_type = input_as.to_s.classify
        else
          record_type = record_class.columns_hash[field_name.to_s].type.to_s.classify
        end

        if mini_column and opts = mini_column[:input_options]
          options = opts.merge options
        end

        input_class = "Conjoin::FormBuilder::#{record_type}Input".constantize

        data = OpenStruct.new({
          name: nested_name,
          record: record,
          value: record.send(field_name),
          options: options,
          errors: record.errors.messages[field_name],
          names: names
        })

        new_input = input_class.new data, app, record

        if record_type != 'Hidden' \
        and not options.key(:wrapper) and options[:wrapper] != false
          wrapper field_name.to_s, nested_name, new_input, options
        else
          new_input.render
        end
      end

      def fields_for field_name, options = {}, &block
        names = [].concat models

        associated_record = record.send field_name

        if scope = options.delete(:scope)
          associated_record = associated_record.send(scope, *options.delete(:scope_args))
        end

        if select = options.delete(:select)
          associated_record = Hash[associated_record.each_with_index.map {|a, i| [i, a]}]

          select.each do |key, select_array|
            select_array = [select_array] unless select_array.is_a? Array

            associated_record.select! do |k, v|
              select_array.include? :"#{v[key]}"
            end
          end
        end

        if name = options.delete(:name)
          field_name = name
        end

        names << "#{field_name}_attributes"

        if !associated_record.kind_of? ActiveRecord::Associations::CollectionProxy \
        and !associated_record.kind_of? ActiveRecord::AssociationRelation \
        and !associated_record.kind_of? Array \
        and !associated_record.kind_of? Hash
          fields = Fields.new app, names, associated_record, block, 0
          fields.render
        else
          html = ''
          if associated_record.kind_of? Array
            associated_record.each_with_index do |current_record, i|
              nested_names = [].concat names
              nested_names << i

              fields = Fields.new app, nested_names, current_record, block, i
              html += fields.render
            end
          else
            associated_record.each do |i, current_record|
              nested_names = [].concat names
              nested_names << i

              fields = Fields.new app, nested_names, current_record, block, i
              html += fields.render
            end
          end

          html
        end

      # rescue
      #   raise "No associated record #{field_name} for #{record.class}"
      end

      def errors_for attr
        mab do
          span class: 'has-error has-feedback form-control-feedback' do
            text! record.errors.messages[attr.to_sym].try :join, ', '
          end
        end
      end

      private

      def id_for field_name
        field_name.gsub(/[^a-z0-9]/, '_').gsub(/__/, '_').gsub(/_$/, '')
      end

      def required?(obj, attr, options)
        if options.key?(:required)
          options[:required]
        else
          target = (obj.class == Class) ? obj : obj.class
          presence = target.validators_on(attr).select { |t| t.class.to_s == 'ActiveRecord::Validations::PresenceValidator' }
          if presence.any?
            is_required = true

            presence.each do |p|
              if p.options[:if]
                is_required &= p.options[:if].call(record)
              end

              if p.options[:unless]
                is_required &= !p.options[:if].call(record)
              end
            end
          else
            is_required = false
          end

          is_required
        end
      end

      def errors? obj, attr
        obj.errors.messages[attr.to_sym]
      end

      def wrapper field_name, nested_name, input, options
        if w = options[:wrapper] and w.is_a? String
          label_width, input_width = w.split ','
        else
          label_width, input_width = [3, 9]
        end

        mab do
          div class: "form-group #{errors?(record, field_name) ? 'has-error has-feedback' : ''}" do
            label for: id_for(nested_name), class: "control-label col-sm-#{label_width}" do
              if required? record, field_name, options
                abbr title: 'required' do
                  text '*'
                end
              end

              i18n_s = nested_name.gsub(/.+\[([a-z\_]+)\](?:.*|)\[([a-z\_]+)\]$/, 'model.\1.\2').gsub(/_attributes/, '')

              i18n_name = options[:label] || R18n.t(i18n_s.gsub(/^model/, 'form.label')) | R18n.t.form.label[field_name] | R18n.t(i18n_s) |  field_name.titleize

              text! i18n_name
            end
            div class: "col-sm-#{input_width}" do
              text! input.render
              if errors = errors?(record, field_name)
                span class: 'help-block has-error' do
                  text errors.join ', '
                end
                span class: 'fa fa-times form-control-feedback'
              end
            end
          end
        end
      end
    end

    class Input
      attr_accessor :app, :data, :options, :record

      def initialize data, app, record
        @data = data
        @app = app
        @record = record
        @options = {
          name: data.name,
          type: :text,
          id: id,
          value: data.value,
          class: ''
        }.merge! data.options
        options[:class] += ' form-control'
        @options
      end

      def id
        data.name.gsub(/[^a-z0-9]/, '_').gsub(/__/, '_').gsub(/_$/, '')
      end

      def nested_name
        # create field names that map to the correct models
        data.names.each_with_index.map do |field, i|
          i != 0 ? "[#{field}]" : field
        end.join
      end

      def errors?
        data.errors
      end

      def render
        if options[:type] == :hidden \
        or (options.key?(:wrapper) and options[:wrapper] == false)
          options[:class] = options[:class].gsub(/form-control/, '')
        end

        display
      end

      def display
        mab { input options }
      end
    end
  end
end
