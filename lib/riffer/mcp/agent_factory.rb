# frozen_string_literal: true
# rbs_inline: enabled

# Generates an anonymous Riffer::Agent subclass for an MCP server.
#
# The generated agent has no model, instructions, or system prompt — it is
# a container for the server's tools, exposed via the registration's +agent+
# attribute.
#
module Riffer::Mcp::AgentFactory
  # Builds a Riffer::Agent subclass configured with the given tools.
  #
  #: (Riffer::Mcp::Manifest, Array[singleton(Riffer::Tool)]) -> singleton(Riffer::Agent)
  def self.build(manifest, tools)
    Class.new(Riffer::Agent) do
      identifier manifest.name
      uses_tools -> { tools }
    end
  end
end
