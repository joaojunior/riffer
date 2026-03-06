# frozen_string_literal: true
# rbs_inline: enabled

# Riffer::Mcp::Manifest holds the configuration for a single MCP server.
#
# +name+     - String identifier used as the registration key and generated-agent identifier.
# +tags+     - Array[Symbol]; normalized to symbols at construction time.
# +endpoint+ - String URL passed to the MCP transport.
# +headers+  - Hash or Proc; resolved once at client initialization time.
#
Riffer::Mcp::Manifest = Struct.new(:name, :tags, :endpoint, :headers, keyword_init: true) do
  def initialize(...)
    super
    self.tags = Array(tags).map(&:to_sym)
  end
end
