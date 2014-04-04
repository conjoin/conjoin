require "rack/csrf"

module Conjoin
  module Csrf
    # Public: Sugar to include a csrf tag
    #
    # Examples:
    #
    #   <form action="/new">
    #     <%= csrf_tag %>
    #     <input type="text" />
    #   </form>
    def csrf_tag
      Rack::Csrf.tag(env)
    end

    # Public: Sugar to access the csrf token
    #
    # Examples:
    #
    #   <%= csrf_token %>
    def csrf_token
      Rack::Csrf.token(env)
    end
  end
end
