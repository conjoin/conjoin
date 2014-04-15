require "conjoin/version"
require "conjoin/recursive_ostruct"
require "conjoin/middleware"
require "conjoin/env_string"
require "conjoin/class_methods"
require "conjoin/cuba"
require "conjoin/seeds"

module Conjoin
  extend ClassMethods

  if not env.mounted?
    require 'active_record'
    require 'action_mailer'
    require 'slim'
    require "tilt/coffee"
    require "tilt/sass"
  end

  autoload :ActiveRecord, "conjoin/active_record"
  autoload :Assets      , "conjoin/assets"
  autoload :Auth        , "conjoin/auth"
  autoload :Environment , "conjoin/environment"
  autoload :FormBuilder , "conjoin/form_builder"
  autoload :I18N        , "conjoin/i18n"
  autoload :Widgets     , "conjoin/widgets"
  autoload :Csrf        , "conjoin/csrf"
  autoload :As          , "conjoin/as"
  autoload :Ui          , "conjoin/ui"
  autoload :JQuery      , "conjoin/jquery"
  autoload :Nav         , "conjoin/nav"
  # ActionMailer
  # https://gist.github.com/acwright/1944639
  # DelayedJob
  # https://gist.github.com/robhurring/732327
end
