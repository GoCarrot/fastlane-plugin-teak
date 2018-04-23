require 'fastlane/action'
require_relative '../helper/teak_helper'

TEAK_SDKS = {
  'air' => {
    basename: 'io.teak.sdk.Teak',
    extension: 'ane',
    s3dir: 'air',
    local_subdirectory: 'bin'
  },
  'unity' => {
    basename: 'Teak',
    extension: 'unitypackage',
    s3dir: 'unity',
    local_subdirectory: nil
  }
}

module Fastlane
  module Actions
    class TeakSdkAction < Action
      def self.run(params)
        FastlaneCore::PrintTable.print_values(config: params, title: "Summary for Teak SDK")

        teak_sdk = TEAK_SDKS[params[:sdk].to_s.downcase]

        # Copy or Download
        if params[:source]
          FileUtils.cp(File.join(source, teak_sdk[:local_subdirectory], "#{teak_sdk[:basename]}.#{teak_sdk[:extension]}"), File.join(params[:destination], "#{teak_sdk[:basename]}.#{teak_sdk[:extension]}"))
        else
          version = params[:version] ? "-#{params[:version]}" : ""
          %x(`curl -o '#{File.join(params[:destination], "#{teak_sdk[:basename]}.#{teak_sdk[:extension]}")}' https://sdks.teakcdn.com/#{params[:sdk].to_s.downcase}/#{teak_sdk[:basename]}#{version}.#{teak_sdk[:extension]}`)
        end
      end

      def self.description
        "Download the Teak SDK"
      end

      def self.authors
        ["Pat Wilson"]
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :sdk,
                                  env_name: "FL_TEAK_SDK_TYPE",
                               description: "The type of Teak SDK, one of: #{TEAK_SDKS.keys.inspect}",
                                  optional: false,
                                      type: Object,
                              verify_block: proc do |value|
                                              UI.user_error!("Value should be a String or Symbol") unless value.kind_of?(String) || value.kind_of?(Symbol)
                                              UI.user_error!("Value should be one of: #{TEAK_SDKS.keys.inspect}") unless TEAK_SDKS.keys.include?(value.to_s.downcase)
                                            end),
          FastlaneCore::ConfigItem.new(key: :destination,
                                  env_name: "FL_TEAK_SDK_DESTINATION",
                               description: "The destination path for the Teak SDK",
                                  optional: false,
                                      type: String,
                              verify_block: proc do |value|
                                              UI.user_error!("Directory does not exist (#{value})") unless File.exist?(value)
                                            end),
          FastlaneCore::ConfigItem.new(key: :version,
                                  env_name: "FL_TEAK_SDK_VERSION",
                               description: "The version of the Teak SDK to install, defaults to latest",
                             default_value: nil,
                                  optional: true,
                                      type: String),
          FastlaneCore::ConfigItem.new(key: :source,
                                  env_name: "FL_TEAK_SDK_SOURCE",
                               description: "Local source for the Teak SDK repository",
                             default_value: nil,
                                  optional: true,
                              verify_block: proc do |value|
                                              UI.user_error!("Directory does not exist (#{value})") unless File.exist?(value)
                                              UI.user_error!("'Teak.unitypackage' or 'io.teak.sdk.Teak.ane' SDK not found in (#{value})") unless File.exist?(File.join(value, 'Teak.unitypackage')) || File.exist?(File.join(value, 'bin', 'Teak.unitypackage'))
                                            end)
        ]
      end

      def self.is_supported?(platform)
        # [:ios, :android].include?(platform)
        true
      end
    end
  end
end
