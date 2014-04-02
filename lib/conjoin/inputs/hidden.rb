module Conjoin
  module FormBuilder
    class HiddenInput < Input
      def display
        options[:type] = :hidden
        super
      end
    end
  end
end
