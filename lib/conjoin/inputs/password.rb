module Conjoin
  module FormBuilder
    class PasswordInput < Input
      def display
        options[:type] = :password
        super
      end
    end
  end
end
