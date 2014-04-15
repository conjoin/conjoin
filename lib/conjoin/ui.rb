module Conjoin
  module Ui
    def panel options = {}, &block
      helper = self

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
  end
end
