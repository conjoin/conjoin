module Conjoin
  module FormBuilder
    class DateInput < Input
      def display
        options[:date] = true
        options[:value] = R18n.l options[:value]
        super
      end
    end
  end
end
