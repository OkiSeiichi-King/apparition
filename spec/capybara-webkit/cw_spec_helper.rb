# frozen_string_literal: true

require 'rspec'
require 'rbconfig'
require 'capybara'

PROJECT_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..')).freeze

$LOAD_PATH << File.join(PROJECT_ROOT, 'lib')

Dir[File.join(PROJECT_ROOT, 'spec', 'support', '**', '*.rb')].each { |file| require(file) }

require 'capybara/apparition'
$webkit_server = Capybara::Webkit::Server.new
$webkit_connection = Capybara::Webkit::Connection.new(server: $webkit_server)
$webkit_browser = Capybara::Webkit::Browser.new($webkit_connection)

$webkit_browser.enable_logging if ENV['DEBUG']

require 'capybara/spec/spec_helper'

Capybara.register_driver :reusable_webkit do |app|
  Capybara::Apparition::Driver.new(app)
end

def has_internet?
  require 'resolv'
  dns_resolver = Resolv::DNS.new
  begin
    dns_resolver.getaddress('example.com')
    true
  rescue Resolv::ResolvError
    false
  end
end

RSpec.configure do |c|
  Capybara::SpecHelper.configure(c)

  c.filter_run_excluding skip_on_windows: !(RbConfig::CONFIG['host_os'] =~ /mingw32/).nil?
  c.filter_run_excluding skip_on_jruby: !defined?(::JRUBY_VERSION).nil?
  c.filter_run_excluding selenium_compatibility: (Capybara::VERSION =~ /^2\.4\./).nil?
  c.filter_run_excluding skip_if_offline: !has_internet?

  c.filter_run_excluding full_description: lambda do |description, _metadata|
    patterns = [
      # Accessing unattached nodes is allowed when reload is disabled - Legacy behavior
      /^Capybara::Session webkit node #reload without automatic reload should not automatically reload/,
      # QtWebkit doesn't support datalist
      /^Capybara::Session webkit #select input with datalist should select an option/,
      # We focus the next window instead of failing when closing windows.
      /^Capybara::Session webkit Capybara::Window\s*#close.*no_such_window_error/,
      # QtWebkit doesn't support HTTP 308 response status
      /^Capybara::Session webkit #click_button should follow permanent redirects that maintain method/,
      # No support for fullscreen window
      /^Capybara::Session webkit Capybara::Window#fullscreen should be able to fullscreen the window/
    ]
    # These tests were implemented in a non-compatible manner in Capybara < 2.12.0 (outerWidth, outerHeight)
    if Gem::Version.new(Capybara::VERSION) < Gem::Version.new('2.12.0')
      patterns << /Capybara::Session webkit Capybara::Window\s*#(size|resize_to|maximize)/ \
               << /Capybara::Session webkit node\s*#set should allow me to change the contents of a contenteditable elements child/
    end
    patterns.any? { |pattern| description =~ pattern }
  end

  c.filter_run :focus unless ENV['TRAVIS']
  c.run_all_when_everything_filtered = true
end

def with_env_vars(vars)
  old_env_variables = {}
  vars.each do |key, value|
    old_env_variables[key] = ENV[key]
    ENV[key] = value
  end

  yield

  old_env_variables.each do |key, value|
    ENV[key] = value
  end
end
