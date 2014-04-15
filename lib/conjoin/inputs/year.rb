require_relative 'select'

module Conjoin
  module FormBuilder
    class YearInput < SelectInput
      def select_options
        years_select = {}
        years = (1900..(Date.today.year+2)).to_a.reverse!

        years.each do |year|
          years_select[year] = year.to_s
        end

        years_select
      end
    end
  end
end
