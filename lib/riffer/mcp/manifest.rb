# frozen_string_literal: true
# rbs_inline: enabled

require "uri"

# Riffer::Mcp::Manifest holds the configuration for a single MCP server.
#
# +name+                - String identifier used as the registration key and generated-agent identifier.
# +tags+                - Array[Symbol]; normalized to symbols at construction time.
# +endpoint+            - String HTTPS URL passed to the MCP transport.
# +discovery_headers+   - Hash or Proc; resolved once when building the discovery client for +tools/list+.
# +credentials_scope+  - Optional symbol hint: +:global+, +:tenant+, +:user+ — documents whether
#   invocation credentials are expected to depend on tenant and/or user keys in +context+ (no ids stored).
#   Apps may treat +:user+ as "user in tenant" and pass both keys in +context+.
#
Riffer::Mcp::Manifest = Struct.new(:name, :tags, :endpoint, :discovery_headers, :credentials_scope, keyword_init: true) do
  def initialize(...)
    super
    self.name = name.to_s.strip
    raise Riffer::ArgumentError, "MCP manifest name is required" if name.empty?

    self.endpoint = endpoint.to_s.strip
    raise Riffer::ArgumentError, "MCP manifest endpoint must be a valid HTTPS URL" unless valid_endpoint?

    self.tags = Array(tags).map(&:to_sym)
    self.credentials_scope = credentials_scope&.to_sym
  end

  private

  def valid_endpoint?
    uri = URI.parse(endpoint)
    uri.is_a?(URI::HTTPS) && uri.host
  rescue URI::InvalidURIError
    false
  end
end
