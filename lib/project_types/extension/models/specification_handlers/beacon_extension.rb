# frozen_string_literal: true
require "base64"
require "fileutils"
require "json"
require_relative "beacon_extension_utils/script_config"
require_relative "beacon_extension_utils/script_config_repository"

module Extension
  module Models
    module SpecificationHandlers
      class BeaconExtension < Default
        SCRIPT_FILE = "beacon-extension.js"
        CONFIG_FILE = "script.config.yml"

        def name
          "Beacon Extension"
        end

        def read_configuration
        end

        def create_file(context, file_path, contents = nil)
          if contents
            File.open(file_path, "w") { |file| file.write(contents) }
          else
            FileUtils.touch(file_path)
          end
        rescue
          context.abort(context.message("features.argo.script_prepare_error"))
        end

        def read_file_contents(context, file_path, &read_file_block)
          context.abort(context.message("features.argo.missing_file_error")) unless File.exist?(file_path)

          begin
            read_file_block.call(file_path)
          rescue StandardError
            context.abort(context.message("features.argo.script_prepare_error"))
          end
        end

        def create(directory_name, context, **_args)
          context.root = File.join(context.root, directory_name)
          FileUtils.makedirs(context.root)

          create_file(context, File.join(context.root, CONFIG_FILE),
            <<~EOS
              runtime_context: sandbox
              version: 1
              runtime_configuration_schema:
                type: object
                fields:
                  configurationKey:
                    name: My configuration field
                    description: This is a description
                    type: single_line_text_field
                    validations:
                    - type: min
                      value: "3"
            EOS

          )
          create_file(context, File.join(context.root, SCRIPT_FILE))
        rescue
          context.abort(context.message("features.argo.script_prepare_error"))
        end

        def config(context)
          ext_config = Extension::Models::SpecificationHandlers::BeaconExtensionUtils::ScriptConfigYmlRepository.new(ctx: context).get!.content

          script_contents = read_file_contents(context, File.join(context.root, SCRIPT_FILE)) do |file_path|
            File.read(file_path).chomp
          end
          {
            runtime_context: ext_config.fetch("runtime_context"),
            serialized_script: Base64.strict_encode64(script_contents),
            runtime_configuration_schema: ext_config.fetch("runtime_configuration_schema").to_json,
          }
        rescue StandardError
          context.abort(context.message("features.argo.script_prepare_error"))
        end
      end
    end
  end
end
