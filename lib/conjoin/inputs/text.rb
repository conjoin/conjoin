module Conjoin
  module FormBuilder
    class TextInput < Input
      def display
        options[:class] += ' form-control'
        value = options.delete :value
        mab do
          textarea options do
            text value
          end
        end
      end
    end
  end
end
