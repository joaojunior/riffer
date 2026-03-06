# frozen_string_literal: true
# rbs_inline: enabled

require "mcp"

# Thin wrapper around the MCP Ruby SDK client (mcp gem v0.8+).
#
# Resolves headers (if a Proc) once at initialization, then provides
# +tools_list+ and +tools_call+ for use by the discovery thread and tool classes.
#
# MCP gem API used:
#   MCP::Client::HTTP.new(url:, headers:)  — HTTP transport (requires faraday)
#   MCP::Client.new(transport:)            — client
#   client.tools                           — Array<MCP::Client::Tool>
#   client.call_tool(tool:, arguments:)    — raw JSON-RPC response Hash
#
class Riffer::Mcp::Client
  #: (endpoint: String, ?headers: (Hash[String, String] | Proc), ?client: untyped?) -> void
  def initialize(endpoint:, headers: {}, client: nil)
    @client = client || begin
      resolved_headers = headers.is_a?(Proc) ? headers.call : headers
      transport = MCP::Client::HTTP.new(url: endpoint, headers: resolved_headers)
      MCP::Client.new(transport: transport)
    end
  end

  # Returns an array of tool definition hashes, each with +:name+, +:description+,
  # and +:input_schema+ keys.
  #
  #: () -> Array[Hash[Symbol, untyped]]
  def tools_list
    @client.tools.map do |tool|
      {
        name: tool.name,
        description: tool.description,
        input_schema: tool.input_schema
      }
    end
  end

  # Calls a tool on the MCP server and returns joined text content from the response.
  #
  #: (String, ?Hash[untyped, untyped]) -> String
  def tools_call(name, arguments = {})
    tool = MCP::Client::Tool.new(name: name, description: nil, input_schema: nil)
    response = @client.call_tool(tool: tool, arguments: arguments)
    content = response.dig("result", "content") || []
    content.filter_map { |item| item["text"] }.join
  end
end
