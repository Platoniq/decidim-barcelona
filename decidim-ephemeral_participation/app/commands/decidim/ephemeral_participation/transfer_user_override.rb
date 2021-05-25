# frozen_string_literal: true

module Decidim
  module EphemeralParticipation
    module TransferUserOverride
      extend ActiveSupport::Concern

      included do
        alias :update_regular_managed_user :update_managed_user

        private

        def update_managed_user
          if managed_user.ephemeral_participant?
            update_conflicting_users
          else
            update_regular_managed_user
          end
        end

        def update_conflicting_users
          update_old_ephemeral_participant
          update_new_ephemeral_participant
        end

        def update_old_ephemeral_participant
          # TODO: move to command
          managed_user.managed  = false
          managed_user.email    = form.email
          managed_user.nickname = nicknamize(managed_user)

          managed_user.save(validate: false)
        end

        def nicknamize(user)
          Decidim::UserBaseEntity.nicknamize(user.name, organization: user.organization)
        end

        def update_new_ephemeral_participant
          Decidim::DestroyAccount.call(
            new_user,
            Decidim::DeleteAccountForm.from_params(reason: form.reason),
          )
        end
      end
    end
  end
end
