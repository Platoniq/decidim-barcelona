# frozen_string_literal: true

module Decidim
  module EphemeralParticipation
    class UpdateEphemeralParticipant < Rectify::Command
      def initialize(user, form)
        @user = user
        @form = form
      end

      def call
        return broadcast(:invalid) if @form.invalid?
        
        update_user

        broadcast(:ok)
      end

      private

      def update_user
        @user.managed  = false

        @user.name     = @form.name
        @user.nickname = @form.nickname
        @user.email    = @form.email
        @user.password = @form.password
        @user.password_confirmation = @form.password_confirmation
        @user.password_confirmation = @form.password_confirmation

        @user.skip_reconfirmation!
        @user.save(validate: false)
        @user.send(:after_confirmation)
      end
    end
  end
end
