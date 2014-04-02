require 'r18n-core'

# https://github.com/ai/r18n
module Conjoin
  module I18N
    include R18n::Helpers

    def self.setup(app)
      app.settings[:default_locale] = 'en-US'
      app.settings[:translations] = File.join(Conjoin.root, 'i18n')
      ::R18n::Filters.off :untranslated
      ::R18n::Filters.on :untranslated_html
      if Conjoin.env.test? or Conjoin.env.development?
        ::R18n.clear_cache!
      end
    end

    def set_locale(req, force_default = false)
      ::R18n.set do
        ::R18n::I18n.default = settings[:default_locale]
        locale = get_locale_from_host
        # You can add support for path language info :) Just do it and pull request it ;)
        # locale = get_locale_from_path if locale.nil?
        if locale.nil? and not force_default
          locales = ::R18n::I18n.parse_http req.env['HTTP_ACCEPT_LANGUAGE']
          if req.params['locale']
            locales.insert 0, req.params['locale']
          elsif req.session['locale']
            locales.insert 0, req.session['locale']
          end
        else
          locales = []
          locales << locale
          locales << settings[:default_locale]
        end
        ::R18n::I18n.new locales, settings[:translations]
      end
    end

    def get_locale_from_host
      # auxiliar method to get locale from the subdomain (assuming it is a valid locale).
      data = req.host.split('.')[0]
      data if ::R18n::Locale.exists? data
    end
  end
end

module R18n
  class << self
    def t(*params)
      if params.first.is_a? String
        params.first.split('.').inject(get.t) { |h, k| h[k.to_sym]  }
      else
        get.t(*params)
      end
    end
  end

  # Override
  # https://github.com/ai/r18n/blob/master/r18n-core/lib/r18n-core/locale.rb#L152
  class Locale
    # Convert +object+ to String. It support Fixnum, Bignum, Float, Time, Date
    # and DateTime.
    #
    # For time classes you can set +format+ in standard +strftime+ form,
    # <tt>:full</tt> (“01 Jule, 2009”), <tt>:human</tt> (“yesterday”),
    # <tt>:standard</tt> (“07/01/09”) or <tt>:month</tt> for standalone month
    # name. Default format is <tt>:standard</tt>.
    def localize(obj, format = nil, *params)
      case obj
      when Integer
        format_integer(obj)
      when Float, BigDecimal
        format_float(obj.to_f)
      when Time, DateTime, Date
        return strftime(obj, format) if format.is_a? String
        return month_standalone[obj.month - 1] if :month == format
        return obj.to_s if :human == format and not params.first.is_a? I18n

        type = obj.is_a?(Date) ? 'date' : 'time'
        format = :standard unless format

        unless respond_to? "format_#{type}_#{format}"
          raise ArgumentError, "Unknown time formatter #{format}"
        end

        send "format_#{type}_#{format}", obj, *params
      else
        obj.to_s
      end
    end

    def format_time_time time, *params
      format_time(time)[1..-1]
    end
  end
end
