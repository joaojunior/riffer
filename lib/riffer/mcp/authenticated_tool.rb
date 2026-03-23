# frozen_string_literal: true
# rbs_inline: enabled

# Wraps MCP-generated tool classes so +tools/call+ uses +Riffer.config.mcp.credentials+
# per invocation while delegating metadata to the inner class.
#
module Riffer::Mcp::AuthenticatedTool
  # Returns one wrapper class per inner tool, sharing +manifest+ and +matched_tags+.
  #
  #: (Array[singleton(Riffer::Tool)], Riffer::Mcp::Manifest, Array[Symbol]) -> Array[singleton(Riffer::Tool)]
  def self.wrap_all(tool_classes, manifest, matched_tags)
    tool_classes.map { |tc| wrap_one(tc, manifest, matched_tags) }
  end

  #: (singleton(Riffer::Tool), Riffer::Mcp::Manifest, Array[Symbol]) -> singleton(Riffer::Tool)
  def self.wrap_one(inner_class, manifest, matched_tags)
    inner = inner_class
    man = manifest
    tags = matched_tags

    Class.new(Riffer::Tool) do
      define_singleton_method(:name) { inner.name }
      define_singleton_method(:description) { inner.description }
      define_singleton_method(:parameters_schema) { |strict: false| inner.parameters_schema(strict: strict) }

      define_method(:call) do |context:, **kwargs|
        cred = Riffer.config.mcp.credentials
        unless cred
          return inner.new.call(context: context, **kwargs)
        end

        headers = cred.call(manifest: man, matched_tags: tags, context: context)
        if headers.nil?
          raise Riffer::Mcp::CredentialsDeniedError,
            "MCP credentials returned nil for server '#{man.name}' during tools/call"
        end

        client = Riffer::Mcp::Client.new(endpoint: man.endpoint, headers: headers)
        text(client.tools_call(inner.name, kwargs))
      end
    end
  end
end
