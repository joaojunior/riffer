# frozen_string_literal: true

require "test_helper"

describe Riffer::Mcp::Manifest do
  describe ".new" do
    it "stores name, endpoint, and headers" do
      manifest = Riffer::Mcp::Manifest.new(name: "github", tags: [:github], endpoint: "https://example.com", headers: {})
      assert_equal "github", manifest.name
      assert_equal "https://example.com", manifest.endpoint
    end

    it "normalizes tags to symbols" do
      manifest = Riffer::Mcp::Manifest.new(name: "srv", tags: ["foo", :bar], endpoint: "https://x.com")
      assert_equal [:foo, :bar], manifest.tags
    end

    it "wraps a single tag in an array" do
      manifest = Riffer::Mcp::Manifest.new(name: "srv", tags: :solo, endpoint: "https://x.com")
      assert_equal [:solo], manifest.tags
    end

    it "defaults tags to empty array when nil" do
      manifest = Riffer::Mcp::Manifest.new(name: "srv", tags: nil, endpoint: "https://x.com")
      assert_equal [], manifest.tags
    end

    it "accepts a Proc for headers" do
      proc_headers = -> { {Authorization: "Bearer token"} }
      manifest = Riffer::Mcp::Manifest.new(name: "srv", tags: [], endpoint: "https://x.com", headers: proc_headers)
      assert_equal proc_headers, manifest.headers
    end
  end
end
