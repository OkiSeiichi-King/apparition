# frozen_string_literal: true

require 'capybara/apparition/cookie'

module Capybara::Apparition
  class CookieJar
    def initialize(cookies)
      @cookies = cookies || []
    end

    def find(name, domain = nil, path = '/')
      # sort by path length because more specific take precendence
      @cookies.sort_by { |c| -c.path.length }.find { |cookie|
        cookie.name.downcase == name.downcase &&
        (domain.nil? || match_domain?(cookie, domain)) &&
        (path.nil? || match_path?(cookie, path))
      }
    end
    alias_method :[], :find

  private

    def match_domain?(cookie, domain)
      domain = "." + domain
      cookie_domain = cookie.domain
      cookie_domain = "." + cookie_domain unless cookie_domain.start_with?('.')
      # cookie_domain.downcase.end_with? domain.downcase
      domain.downcase.end_with? cookie_domain.downcase
    end

    def match_path?(cookie, path)
      # cookie.path.start_with? path
      path.start_with? cookie.path
    end
  end
end
