require 'rspec'
require 'json-schema'

module JSON
  module SchemaMatchers
    RSpec.configure do |c|
      c.add_setting :json_schemas, default: {}
    end

    class MatchJsonSchemaMatcher
      def initialize(schema_name, validation_opts = {})
        @schema_name = schema_name
        @validation_opts = validation_opts
      end

      def matches?(actual)
        @actual = actual
        schema = schema_for_name(@schema_name)
        if schema.nil?
          @errors = [
            "No schema defined for #{@schema_name}",
            "Add a line to your RSpec.configure block to define the schema:",
            "  RSpec.configure do |config|",
            "    config.json_schemas[:my_remote_schema] = 'path/to/schema'",
            "    config.json_schemas[:my_inline_schema] = '{\"json\": \"schema\"}'",
            "  end"]
          return false
        end
        @errors = JSON::Validator.fully_validate(schema_for_name(@schema_name), @actual, @validation_opts)

        if @errors.any?
          @errors.unshift("Expected JSON object to match schema identified by #{@schema_name}, #{@errors.count} errors in validating")
          return false
        else
          return true
        end
      end

      def failure_message
        @errors.join("\n")
      end

      def failure_message_when_negated
        "Expected JSON object not to match schema identified by #{@schema_name}"
      end

      def schema_for_name(schema)
        RSpec.configuration.json_schemas[schema]
      end
    end

    def match_json_schema(schema_name, validation_opts = {})
      MatchJsonSchemaMatcher.new(schema_name, validation_opts)
    end
  end
end
