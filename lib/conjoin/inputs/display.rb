module Conjoin
  module FormBuilder
    class DisplayInput < Input
      def display
        options[:class].gsub!(/form-control/, '')
        options[:class] += ' form-control-static'

        mab do
          p class: options[:class] do
            text options[:value]
          end
        end
      end
    end
  end
end
