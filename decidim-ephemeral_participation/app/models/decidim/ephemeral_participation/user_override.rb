# frozen_string_literal: true

module Decidim
  module EphemeralParticipation
    module UserOverride
      extend ActiveSupport::Concern

      included do
        scope :ephemeral_participant, -> { where("extended_data ? 'ephemeral_participation'") }

        def ephemeral_participant?
          managed? && ephemeral_participation_data.present?
        end

        def ephemeral_participation_data
          extended_data.fetch("ephemeral_participation", {})
        end

        def verified_ephemeral_participant?
          return false unless ephemeral_participant?

          Decidim::Authorization.exists?(
            user: self,
            name: ephemeral_participation_data["authorization_name"]
          )
        end
      end
    end
  end
end
