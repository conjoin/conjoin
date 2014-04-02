module Conjoin
  module FormBuilder
    class FileInput < Input
      def display
        key = options[:s3_upload_path].call(record)

        mab do
          unless options[:value]
            div id: id, name: options[:name], class: 'file s3-uploader', value: options[:value]
          end
          input id: id, type: :hidden, name: options[:name], class: 'form-control file s3-uploader', value: options[:value]
          text! S3Uploader.js_button(id, key, options[:callback_url], options[:callback_params])
        end
      end
    end
  end
end
