module Conjoin
  module FormBuilder
    class TimeInput < Input
      def display
        options[:time]  = true
        options[:value] = app.l options[:value], :time
        super
      end
    end
  end
end
