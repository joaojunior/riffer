# frozen_string_literal: true
# rbs_inline: enabled

# Per-server state managed by Riffer::Mcp::Registry.
#
# Created when a server is registered. Spawns a background thread to discover
# tools via the MCP +tools/list+ call, then generates tool and agent classes.
#
class Riffer::Mcp::Registration
  # The manifest that describes this server.
  attr_reader :manifest #: Riffer::Mcp::Manifest

  # Generated Riffer::Tool subclasses (empty until discovery completes).
  attr_reader :tools #: Array[singleton(Riffer::Tool)]

  # Generated Riffer::Agent subclass (nil until discovery completes).
  attr_reader :agent #: singleton(Riffer::Agent)?

  #: (Riffer::Mcp::Manifest) -> void
  def initialize(manifest)
    @manifest = manifest
    @ready = false
    @tools = []
    @agent = nil
    @mutex = Mutex.new
    spawn_discovery_thread
  end

  # Returns true once tool discovery has completed successfully.
  #
  #: () -> bool
  def ready?
    @mutex.synchronize { @ready }
  end

  # Blocks the calling thread until this registration is ready or the timeout elapses.
  #
  # Raises Riffer::Mcp::TimeoutError if +Riffer.config.mcp.wait_timeout+ seconds pass
  # without the registration becoming ready.
  #
  #: () -> void
  def wait_until_ready!
    deadline = Time.now + Riffer.config.mcp.wait_timeout
    loop do
      return if ready?
      raise Riffer::Mcp::TimeoutError, "MCP server '#{@manifest.name}' did not become ready within #{Riffer.config.mcp.wait_timeout}s" if Time.now >= deadline
      sleep 0.05
    end
  end

  private

  #: () -> Thread
  def spawn_discovery_thread
    Thread.new do
      client = build_client
      tool_defs = client.tools_list
      tools = Riffer::Mcp::ToolFactory.build(client, tool_defs)
      agent = Riffer::Mcp::AgentFactory.build(@manifest, tools)

      @mutex.synchronize do
        @tools = tools
        @agent = agent
        @ready = true
      end
    rescue => _e
      # Leave @ready = false — callers apply the on_pending strategy
    end
  end

  #: () -> Riffer::Mcp::Client
  def build_client
    Riffer::Mcp::Client.new(endpoint: @manifest.endpoint, headers: @manifest.discovery_headers || {})
  end
end
