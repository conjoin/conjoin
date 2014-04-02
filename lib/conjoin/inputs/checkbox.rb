module Conjoin
  module FormBuilder
    class CheckboxInput < Input
      def display
        options[:value]   = 'on' if data.value == true
        options[:checked] = 'checked' if data.value
        options[:type]    = :checkbox
        options[:class].gsub!(/form-control/, '')

        super
      end
    end
  end
end
