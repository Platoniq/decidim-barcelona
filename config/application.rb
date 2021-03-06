# frozen_string_literal: true
require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DecidimBarcelona
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Locales
    config.i18n.available_locales = %w(ca es)
    config.i18n.default_locale = :ca

    # Make decorators available
    config.to_prepare do
      Dir.glob(Rails.root + 'app/overrides/**/*_decorator*.rb').each do |file|
        require_dependency(file)
      end
    end
  end
end
