# MCP

Riffer can consume third-party [Model Context Protocol](https://modelcontextprotocol.io) (MCP) servers as tool sources. Tools are discovered automatically at registration time — no handwritten Ruby per tool required.

## Overview

1. Register an MCP server globally with `Riffer::Mcp.register`.
2. Opt an agent into that server's tools using the `use_mcp` DSL.
3. The agent picks up the tools and calls them like any other Riffer tool.

## Registering a Server

```ruby
Riffer::Mcp.register(
  name: "github",        # unique identifier
  tags: [:github],       # agents opt-in by tag
  endpoint: "https://mcp.github.com",
  headers: -> { {Authorization: "Bearer #{ENV['GITHUB_TOKEN']}"} }
)
```

`register` returns immediately. Tool discovery runs in a background thread. Use `on_pending` (see below) to control agent behaviour while discovery is in progress.

`headers` accepts a Hash or a Proc. The Proc is called once when the client is initialized — useful for tokens that may rotate between registrations.

## Tags

Tags are entirely up to your application; Riffer does not define a canonical vocabulary. Each server may declare multiple tags; an agent includes every registration that shares **any** tag passed to `use_mcp`.

When MCPs are registered, assign **stable bucket tags** so agent classes can opt in without listing every server name—for example `tags: [:connectors, :github]` with `use_mcp :connectors` for all enabled connectors, or `use_mcp :github` for that integration only.

## Opting an Agent In

```ruby
class ResearchAgent < Riffer::Agent
  model "openai/gpt-4o"
  instructions "You are a research assistant."

  use_mcp :github
end
```

`use_mcp` accepts any tag registered via `Riffer::Mcp.register`. Multiple calls accumulate — the agent receives tools from all matching servers:

```ruby
class MultiAgent < Riffer::Agent
  model "openai/gpt-4o"

  use_mcp :github
  use_mcp :jira
end
```

MCP tools are appended after any tools declared with `uses_tools`.

## Handling Pending Servers

Discovery is asynchronous. When an agent runs before a server is ready, the `on_pending` strategy determines what happens:

| Strategy | Behaviour |
|----------|-----------|
| `:ignore` | Tools from that server are omitted (default) |
| `:wait` | Blocks until ready or `wait_timeout` seconds, then raises `TimeoutError` |
| `:raise` | Immediately raises `NotReadyError` |

Set the global default:

```ruby
Riffer.configure do |config|
  config.mcp.on_pending = :wait
  config.mcp.wait_timeout = 30  # seconds
end
```

Override per `use_mcp` call:

```ruby
use_mcp :github, on_pending: :wait
use_mcp :jira, on_pending: :ignore
```

## Unregistering a Server

```ruby
Riffer::Mcp.unregister("github")
```

Subsequent agent runs will not include tools from that server. Call `register` again (with fresh headers if needed) to re-register.

## Introspection

```ruby
Riffer::Mcp.registrations
# => {"github" => #<Riffer::Mcp::Registration ...>, ...}

reg = Riffer::Mcp.registrations["github"]
reg.ready?   # => true / false
reg.tools    # => [<Class:...>, ...]  (Riffer::Tool subclasses)
reg.agent    # => <Class:...>         (Riffer::Agent subclass)
```

## Error Classes

| Class | Raised when |
|-------|-------------|
| `Riffer::Mcp::NotReadyError` | `on_pending: :raise` and server not ready |
| `Riffer::Mcp::TimeoutError` | `on_pending: :wait` and `wait_timeout` exceeded |

Both inherit from `Riffer::Mcp::Error < Riffer::Error`.

## Requirements

The `mcp` gem is a runtime dependency of Riffer. The HTTP transport requires `faraday`:

```ruby
gem "faraday"
```
