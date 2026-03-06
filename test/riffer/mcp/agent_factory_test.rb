# frozen_string_literal: true

require "test_helper"

describe Riffer::Mcp::AgentFactory do
  let(:manifest) do
    Riffer::Mcp::Manifest.new(name: "my-server", tags: [:srv], endpoint: "https://x.com")
  end

  let(:tool_class) do
    klass = Class.new(Riffer::Tool)
    klass.instance_variable_set(:@identifier, "my_tool")
    klass
  end

  let(:agent_class) { Riffer::Mcp::AgentFactory.build(manifest, [tool_class]) }

  describe ".build" do
    it "returns a Riffer::Agent subclass" do
      assert agent_class < Riffer::Agent
    end

    it "sets the identifier from the manifest name" do
      assert_equal "my-server", agent_class.identifier
    end

    it "resolves tools from the provided tools array" do
      agent_instance = agent_class.allocate
      agent_instance.instance_variable_set(:@context, nil)
      assert_equal [tool_class], agent_instance.send(:resolve_uses_tools_config)
    end
  end
end
