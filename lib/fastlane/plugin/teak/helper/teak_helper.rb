require 'fastlane_core/ui/ui'
require 'securerandom'
require 'match'
require 'tmpdir'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class TeakHelper
      # class methods that you define here become available in your action
      # as `Helper::TeakHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the teak plugin helper!")
      end

      # Execute a block that will be provided with a path to a p12, a provisioning profile, and a passphrase
      def self.with_credentials_for(app_id, type: 'development')
        keychain_name = SecureRandom.hex

        # Create temporary keychain
        Actions::CreateKeychainAction.run(
          name: keychain_name,
          default_keychain: false,
          unlock: true,
          timeout: 10,
          lock_when_sleeps: true,
          password: SecureRandom.hex
        )

        # Download the certificates
        params = FastlaneCore::Configuration.create(Match::Options.available_options, {
          app_identifier: app_id,
          type: type,
          readonly: true,
          keychain_name: keychain_name
        })
        Actions::MatchAction.run(params)

        # Get the location of the provisioning profile
        provisioning_profile_path_env = Match::Utils.environment_variable_name_profile_path(
          app_identifier: app_id,
          type: type
        )

        # Export p12
        Dir.mktmpdir do |tmpdir|
          p12_password = SecureRandom.hex
          p12_file = File.join(tmpdir, "temp.p12")
          Actions.sh("security", "export", "-k", keychain_name, "-t", "identities",
                     "-f", "pkcs12", "-P", p12_password, "-o", p12_file, log: false)

          # Call block
          yield(p12_file, p12_password, ENV[provisioning_profile_path_env])
        end
      ensure
        # Cleanup temporary keychain
        Actions::DeleteKeychainAction.run(name: keychain_name)
      end
    end
  end
end
