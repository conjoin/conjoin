module Conjoin
  module FormBuilder
    class SelectInput < Input
      def display
        append_button = options.delete :append_button
        if options[:multiple]
          options[:name] += '[]'
        end

        content = mab do
          # automatically add a prompt by default
          options[:prompt] = 'true' unless options.key? :prompt
          options[:class] += ' selectize' unless options.delete(:selectize) == false
          selected_value = options.delete :value

          select options do
            opts = {
              value: ''
            }

            if prompt = options.delete(:prompt)
              opts['selected'] = 'selected' unless selected_value
              option opts do
                text! prompt.to_s == 'true' ? 'Please Choose One.' : prompt
              end
            end

            if not options[:group]
              select_options.invert.each do |name, value|
                option render_opts(value, selected_value, opts) do
                  text (name != name.upcase ? name.titleize : name)
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

        if not append_button
          content
        else
          mab do
            div class: 'input-group' do
              text! content
              div class: 'input-group-btn' do
                button class: 'btn btn-primary', type: 'button', 'on-click-get' => append_button[:href] do
                  text append_button[:text]
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
        elsif selected_value.is_a? Array
          opts['selected'] = 'selected' if selected_value.include? value.to_s
        else
          opts['selected'] = 'selected' if selected_value.to_s == value.to_s
        end

        opts
      end
    end
  end
end
