module Conjoin
  module ClassMethods
    attr_accessor :root

    def env
      @env ||= EnvString.new(
        ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
      )
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
