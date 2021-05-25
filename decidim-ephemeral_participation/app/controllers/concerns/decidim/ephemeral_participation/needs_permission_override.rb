# frozen_string_literal: true

module Decidim
  module EphemeralParticipation
    module NeedsPermissionOverride
      extend ActiveSupport::Concern

      included do
        alias :old_user_has_no_permission  :user_has_no_permission
        alias :old_permissions_context     :permissions_context

        def user_has_no_permission
          if request.xhr?
            new_user_has_no_permission
          else
            old_user_has_no_permission
          end
        end

        def permissions_context
          old_permissions_context.merge(new_permissions_context)
        end

        private

        def new_user_has_no_permission
          render js: unauthorized_error_flash_message_js
        end

        def unauthorized_error_flash_message_js
          <<~JAVASCRIPT
            $alertBoxParsedHtml = $.parseHTML('#{unauthorized_error_flash_message_html}')[0].outerHTML;
            alertBoxNotFound    = $('#content').html().indexOf($alertBoxParsedHtml) == -1;

            if (alertBoxNotFound) $('#content').prepend($alertBoxParsedHtml);

            $(window).scrollTop(0);
          JAVASCRIPT
        end

        def unauthorized_error_flash_message_html
          flash.clear

          flash.now[:alert] = unauthorized_message

          helpers.display_flash_messages
        end

        def unauthorized_message
          if (current_user && current_user.ephemeral_participant?)
            unauthorized_ephemeral_participant_message
          else
            I18n.t("actions.unauthorized", scope: "decidim.core")
          end
        end

        def unauthorized_ephemeral_participant_message
          t(
            "decidim.ephemeral_participation.actions.unauthorized",
            link: (
              helpers.link_to(
                I18n.t("decidim.ephemeral_participation.actions.unauthorized_link"),
                decidim_ephemeral_participation.edit_ephemeral_participant_path(current_user),
              )
            )
          ).html_safe
        end

        def new_permissions_context
          {
            request: request,
          }
        end
      end
    end
  end
end
