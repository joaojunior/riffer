# Riffer Project Memory

## Key Facts
- Ruby 3.4.8 (rbenv), run with `rbenv exec bundle exec rake`
- Minitest 6 — no `minitest/mock` module; `.stub` unavailable. Use DI or `define_singleton_method` for test doubles.
- StandardRB linter: `bundle exec rake standard` / `rake standard:fix`
- Zeitwerk autoloading: file paths must match module/class names exactly

## Testing Conventions
- Minitest spec DSL (`describe`/`it`/`let`/`before`/`after`)
- VCR cassettes in `test/fixtures/vcr_cassettes/` for real HTTP
- `let` blocks run with test object as `self`; do NOT capture `let` values inside `define_singleton_method` blocks — use a local variable instead (e.g. `td = tool_def`)
- No `.stub` — use dependency injection (`client:` param) or subclass overrides

## MCP Integration (merged in 2026-03)
New files: `lib/riffer/mcp.rb`, `lib/riffer/mcp/{manifest,registry,registration,client,tool_factory,agent_factory}.rb`
Modified: `riffer.gemspec` (adds `mcp ~> 0.3`), `lib/riffer/config.rb` (Mcp struct), `lib/riffer/agent.rb` (use_mcp DSL)

MCP gem v0.8 API:
- `MCP::Client.new(transport:)` — transport only, no name/version
- `MCP::Client::HTTP.new(url:, headers:)` — HTTP transport (needs faraday)
- `client.tools` → `Array<MCP::Client::Tool>` with `.name`, `.description`, `.input_schema`
- `client.call_tool(tool:, arguments:)` → raw Hash, content at `response.dig("result", "content")`
- No `MCP::Transport::Streamable` — HTTP transport is `MCP::Client::HTTP`

`Riffer::Mcp::Client` accepts `client:` kwarg for DI in tests.
`Riffer::Mcp::Registration#build_client` is overrideable for tests.
`Riffer::Mcp::Registry.reset!` clears the store (use in before/after).
