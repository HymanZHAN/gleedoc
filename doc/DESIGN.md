# Design and overall architecture

```
src/
  gleedoc.gleam           # Main entry point, public functions and types
  gleedoc/
    internal/
      extract.gleam         # Line-based doc comment extraction
      parse.gleam           # Markdown code block parsing
      generate.gleam        # Test file generation
      scan.gleam            # Public names and imports extraction with glance
```

## Key dependencies

| Package      | Role                            |
| ------------ | ------------------------------- |
| `glance`     | Gleam source parser             |
| `simplifile` | Cross-target file I/O           |
| `snag`       | Lightweight error handling      |
| `shellout`   | Cross-platform shell operations |
| `argv`       | CLI arguments parsing           |
| `envoy`      | Environment variables           |

## How other languages do it

| Language   | Approach                                                                      | Key Difference from Gleam                 |
| ---------- | ----------------------------------------------------------------------------- | ----------------------------------------- |
| **Rust**   | `cargo test` compiles ` ```rust ` blocks from `///` comments. No REPL needed. | Gleam follows this model closely.         |
| **Elixir** | `doctest Module` parses `iex>` prompts from `@doc` strings.                   | Elixir has a REPL; Gleam does not.        |
| **Python** | `doctest` parses `>>>` prompts from docstrings.                               | Python is interpreted; Gleam is compiled. |

Because Gleam is a compiled language with no built-in REPL, **gleedoc** adopts Rust's approach: doc blocks are treated as standalone Gleam code that gets compiled and executed. If a block panics, the test fails.
