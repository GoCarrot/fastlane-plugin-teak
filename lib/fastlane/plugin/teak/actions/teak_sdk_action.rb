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
    local_subdirectory: ''
  }
}

module Fastlane
  module Actions
    class TeakSdkAction < Action
      def self.run(params)
        FastlaneCore::PrintTable.print_values(config: params, title: "Summary for Teak SDK")

        teak_sdk = TEAK_SDKS[params[:sdk].to_s.downcase]
        out_sdk_path = File.join(params[:destination], "#{teak_sdk[:basename]}.#{teak_sdk[:extension]}")

        # Copy or Download
        if params[:source]
          FileUtils.cp(File.join(params[:source], teak_sdk[:local_subdirectory], "#{teak_sdk[:basename]}.#{teak_sdk[:extension]}"), out_sdk_path)
        else
          version = params[:version] ? "-#{params[:version]}" : ""

          Actions.sh("curl", "--fail", "-o", out_sdk_path,
                     "https://sdks.teakcdn.com/#{params[:sdk].to_s.downcase}/#{teak_sdk[:basename]}#{version}.#{teak_sdk[:extension]}",
                     error_callback: proc do
                                       UI.user_error!("Could not download version #{params[:version]}")
                                     end)
        end

        # Figure out the version of the SDK
        teak_sdk_version = nil
        Dir.mktmpdir do |tmpdir|
          case params[:sdk]
          when :air
            Actions.sh("unzip", out_sdk_path, "-d", tmpdir, log: false)
            teak_sdk_version = File.read(File.join(tmpdir, "META-INF", "ANE", "extension.xml")).match(%r[<versionNumber>(.*)<\/versionNumber>]).captures.first
          when :unity
            Actions.sh("tar", "-xf", out_sdk_path, "-C", tmpdir, log: false)
            teak_version_dir = Dir.glob("#{tmpdir}/*").find do |f|
              pathname = File.join(f, "pathname")
              File.directory?(f) && File.exist?(pathname) && File.read(pathname) == "Assets/Teak/TeakVersion.cs"
            end
            teak_sdk_version = File.read(File.join(teak_version_dir, "asset")).match(/return "(.*)"/).captures.first
          end
        end

        # Return SDK version
        teak_sdk_version
      end

      def self.description
        "Download the Teak SDK"
      end

      def self.return_value
        "The version of the Teak SDK which was downloaded or copied"
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
        true
      end
    end
  end
end
