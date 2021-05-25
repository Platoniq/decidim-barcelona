# frozen_string_literal: true

module Decidim
  module EphemeralParticipation
    class EphemeralParticipantsController < Decidim::ApplicationController
      include FormFactory

      def create
        enforce_permission_to(:create, :ephemeral_participant)

        # TODO: move to command
        sign_in(new_ephemeral_participant) unless current_user
        flash[:notice] = I18n.t("create", scope: "decidim.ephemeral_participation.ephemeral_participants")
        
        redirect_to(authorization_path)
      end

      def edit
        enforce_permission_to(:update, :ephemeral_participant, current_user: current_user)

        @form = form(EphemeralParticipantForm).from_model(current_user)

        render(layout: "layouts/decidim/ephemeral_participation/user_profile")
      end

      def update
        enforce_permission_to(:update, :ephemeral_participant, current_user: current_user)

        @form = form(EphemeralParticipantForm).from_params(params)

        UpdateEphemeralParticipant.call(current_user, @form) do
          on(:ok) do
            flash[:notice] = I18n.t("update.success", scope: "decidim.ephemeral_participation.ephemeral_participants")

            bypass_sign_in(current_user)

            redirect_to(Decidim::Core::Engine.routes.url_helpers.account_path)
          end

          on(:invalid) do
            flash[:alert] = I18n.t("update.error", scope: "decidim.ephemeral_participation.ephemeral_participants")

            render(action: :edit)
          end
        end
      end

      def destroy
        enforce_permission_to(:destroy, :ephemeral_participant, current_user: current_user)

        # TODO: move to command
        # TODO: handle verification conflicts
        current_user.invalidate_all_sessions!
        current_user.destroy unless current_user.verified_ephemeral_participant?
        sign_out(current_user)
        flash[:notice] = I18n.t("destroy", scope: "decidim.ephemeral_participation.ephemeral_participants")

        redirect_to(redirect_url)
      end

      private

      def new_ephemeral_participant
        Decidim::User.create(
          organization: component.organization,
          managed: true,
          tos_agreement: true,
          extended_data: {
            ephemeral_participation: {
              authorization_name: authorization_name,
              component_id: component.id,
              permissions:  component.ephemeral_participation_permissions,
              redirect_url: redirect_url
            }
          }
        )
      end

      def authorization_path
        Decidim::Verifications::Adapter.from_element(authorization_name).root_path(redirect_url: redirect_url)
      end

      def authorization_name
        component.organization.ephemeral_participation_authorization
      end

      def component
        @component ||= Decidim::Component.find(params[:component_id])
      end
    end
  end
end
