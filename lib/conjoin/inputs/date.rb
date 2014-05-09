module Conjoin
  module FormBuilder
    class DateInput < Input
      def display
        options[:date] = true
        options[:value] = R18n.l options[:value]

        append_button       = options.delete :append_button

        content = super

        if append_button
          content = mab do
            div class: 'input-group' do
              text! content
              div class: 'input-group-btn' do
                button class: 'btn btn-primary', type: append_button[:type] || 'button', 'on-click-get' => append_button[:href] do
                  text append_button[:text]
                end
              end
            end
          end
        end

        content
      end
    end
  end
end
