# frozen_string_literal: true
# rbs_inline: enabled

# Riffer::Mcp::Manifest holds the configuration for a single MCP server.
#
# +name+                - String identifier used as the registration key and generated-agent identifier.
# +tags+                - Array[Symbol]; normalized to symbols at construction time.
# +endpoint+            - String URL passed to the MCP transport.
# +discovery_headers+   - Hash or Proc; resolved once when building the discovery client for +tools/list+.
# +credentials_scope+  - Optional symbol hint: +:global+, +:tenant+, +:user+ — documents whether
#   invocation credentials are expected to depend on tenant and/or user keys in +context+ (no ids stored).
#   Apps may treat +:user+ as "user in tenant" and pass both keys in +context+.
#
Riffer::Mcp::Manifest = Struct.new(:name, :tags, :endpoint, :discovery_headers, :credentials_scope, keyword_init: true) do
  def initialize(...)
    super
    self.name = name.to_s
    self.tags = Array(tags).map(&:to_sym)
    self.credentials_scope = credentials_scope&.to_sym
  end
end
