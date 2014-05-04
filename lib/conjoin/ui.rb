module Conjoin
  module Ui
    def panel options = {}, &block
      helper = self

      options[:header] = options.delete :title if options.key? :title

      mab do
        div class: 'panel panel-default', id: options[:id] do
          if options.key? :header
            div class: 'panel-heading' do
              h3 class: 'panel-title' do
                if options.key? :icon
                  fa_icon options[:icon]
                end
                text! options[:header]
              end
            end
          end
          div class: "panel-body #{options.key?(:no_padding) ? 'no-padding' : ''}" do
            text! helper.instance_exec(&block)
          end
        end
      end
    end

    UNITS = %W(B KB MB GB TB).freeze

    def number_to_human_size number
      number = number.to_i

      if number.to_i < 1024
        exponent = 0

      else
        max_exp  = UNITS.size - 1

        exponent = ( Math.log( number ) / Math.log( 1024 ) ).to_i # convert to base
        exponent = max_exp if exponent > max_exp # we need this to avoid overflow for the highest unit

        number  /= 1024 ** exponent
      end

      "#{number} #{UNITS[ exponent ]}"
    end
  end
end
