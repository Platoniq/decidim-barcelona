# frozen_string_literal: true

module Decidim
  module EphemeralParticipation
    module EphemeralParticipable
      extend ActiveSupport::Concern

      included do
        EPHEMERAL_PARTICIPANT_SESSION_DURATION = 30.minutes

        before_action :check_ephemeral_participant_session_expired, if: :ephemeral_participant?
        before_action :check_ephemeral_participant_authorized,      if: :ephemeral_participant?

        helper_method :ephemeral_participant_session_remaining_time_in_minutes

        def ephemeral_participant_session_remaining_time_in_minutes
          return false unless ephemeral_participant?

          (ephemeral_participant_session_remmaining_time / 1.minute).round
        end

        private

        def ephemeral_participant?
          current_user && current_user.ephemeral_participant?
        end

        def check_ephemeral_participant_session_expired
          return if ephemeral_participant_session_remmaining_time.positive?

          DestroyEphemeralParticipant.call(request, current_user) do
            on(:ok) do
              flash[:notice] = I18n.t("destroy", scope: "decidim.ephemeral_participation.ephemeral_participants")

              redirect_to(Decidim::Core::Engine.routes.url_helpers.root_path)
            end
          end
        end

        def ephemeral_participant_session_remmaining_time
          (current_user.created_at + EPHEMERAL_PARTICIPANT_SESSION_DURATION) - Time.current
        end

        def check_ephemeral_participant_authorized
          return if current_user.verified_ephemeral_participant?
          return if new_authorization_path?
          return if edit_ephemeral_participant_path?
          return if flash.any?

          flash.now[:warning] = unverified_ephemeral_participant_message
        end

        # TODO: handle authorization with engines
        # TODO: recognize any authorization path
        def new_authorization_path?
          request.path == Decidim::Verifications::Engine.routes.url_helpers.new_authorization_path
        end

        def edit_ephemeral_participant_path?
          request.path == Decidim::EphemeralParticipation::Engine.routes.url_helpers.edit_ephemeral_participant_path(current_user)
        end

        # TODO: move to presenter
        def unverified_ephemeral_participant_message
          I18n.t(
            "decidim.ephemeral_participation.actions.unverified",
            link: (
              helpers.link_to(
                I18n.t("decidim.ephemeral_participation.actions.unverified_link"),
                (
                  Decidim::Verifications::Adapter
                  .from_element(current_user.ephemeral_participation_data["authorization_name"])
                  .root_path(redirect_url: current_user.ephemeral_participation_data["redirect_url"])
                ),
              )
            )
          ).html_safe
        end
      end
    end
  end
end