module Conjoin
  module FormBuilder
    class SelectInput < Input
      @select_options = {}

      def display
        mab do
          # automatically add a prompt by default
          options[:prompt] = true unless options.key? :prompt
          options[:class] += ' select2'
          selected_value = options.delete :value

          select options do
            if prompt = options.delete(:prompt)
              opts = {
                value: ''
              }
              opts['selected'] = 'selected' unless selected_value
              option opts do
                text prompt.to_s == 'true' ? 'Please Choose One.' : prompt
              end
            end

            if not options[:group]
              select_options.each do |name, value|
                option render_opts(value, selected_value, opts) do
                  text name.titleize
                end
              end
            else
              select_options.each do |group_select, group|
                optgroup label: group.to_s.titleize do
                  group_select.each do |value, name|
                    option render_opts(value, selected_value, opts) do
                      text name.titleize
                    end
                  end
                end
              end
            end
          end
        end
      end

      def render_opts value, selected_value, opts
        opts = {
          value: value
        }
        if selected_value.is_a? ActiveRecord::Associations::CollectionProxy
          opts['selected'] = 'selected' if selected_value.map(&:id).include? value
        else
          opts['selected'] = 'selected' if selected_value == value.to_s
        end

        opts
      end

      def self.select_options
        @select_options
      end

      def select_options
        self.class.select_options.invert
      end
    end
  end
end
