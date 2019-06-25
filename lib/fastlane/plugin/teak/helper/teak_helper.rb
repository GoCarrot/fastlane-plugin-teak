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
      def self.with_credentials_for(app_id, type: 'development', match_options: { readonly: true })
        keychain_name = SecureRandom.hex
        keychain_pass = SecureRandom.hex

        # Create temporary keychain
        Actions::CreateKeychainAction.run(
          name: keychain_name,
          default_keychain: false,
          unlock: true,
          lock_when_sleeps: true,
          password: keychain_pass
        )

        # Download the certificates
        params = FastlaneCore::Configuration.create(Match::Options.available_options, {
          app_identifier: app_id,
          type: type,
          keychain_name: keychain_name
        }.merge(match_options))
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
          yield(p12_file, p12_password, ENV[provisioning_profile_path_env], keychain_name, keychain_pass)
        end
      ensure
        # Cleanup temporary keychain
        Actions::DeleteKeychainAction.run(name: keychain_name)
      end

      def self.with_kms_for(file, ciphertext)
        Dir.mktmpdir do |tmpdir|
          temp_file = File.join(tmpdir, SecureRandom.hex)
          Actions.sh("openssl", "enc", "-d", "-aes-256-cbc", "-in", file, "-out", temp_file, "-k",
                     `aws kms decrypt --ciphertext-blob fileb://#{ciphertext} --output text --query Plaintext | base64 --decode`.force_encoding('BINARY'), log: false)
          yield(temp_file)
        end
      end
    end
  end
end
