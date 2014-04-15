module Conjoin
  module FormBuilder
    class RadioInput < Input
      def display
        options[:type] = :radio
        options[:class].gsub!(/form-control/, '')

        radios = options[:radios] || [:yes, :no]

        mab do
          radios.each_with_index do |name, i|
            opts = options.dup

            name = name.to_s
            opts[:value] = name
            opts[:id]    =  "#{options[:id]}_#{i}"

            if (opts[:value] == 'no' and data.value == 'no') \
            or (opts[:value] == 'yes' and data.value == 'yes') \
            or (opts[:value] == data.value)
              opts[:checked] = 'checked'
            else
              opts.delete :checked
            end

            label class: 'radio-inline' do
              input opts
              text! name.humanize
            end
          end
        end
      end
    end
  end
end
