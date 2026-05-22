# Roadmap

### Basics

- [x] `gleeunit`-compatible test generation from ` ```gleam ` fenced code blocks in source files' doc comments
- [x] Smart imports handling: import merging and import generation from source file's public names
- [x] Single-command `gleam run -m gleedoc` CLI experience
- ~~[x] Test file generation with OS-native line breaks: `\n` on Linux and Mac, `\r\n` on Windows~~ (reverted, as per [this comment](https://github.com/gleam-lang/gleam/pull/2762#pullrequestreview-1945733771))

## Additional features before 1.0

- [x] Offer an `extra_imports` option to apply extra imports to all generated test files
- [x] Source-mapped error reporting
- [x] Automatic formatting for generated tests
- [x] Single-command `gleam test` CLI experience without needing to run `gleam run -m gleedoc` before `gleam test`.
- [x] Module level doc tests
- [x] An `ignore` or `skip` attribute to exclude a code block from doc test generation
- [x] Offer a `preserve_tests` option to control whether generated tests should be preserved after test run

### Missing Features (compared to Rust, Elixir, and Python)

- 📆 - Planned for 1.0
- 🛑 - Not Planned for 1.0
- ✅ - Implemented

| Feature                                | Rust       | Elixir      | Python     | **gleedoc** |
| -------------------------------------- | ---------- | ----------- | ---------- | ----------- |
| Single-command CLI experience          | ✅         | ✅          | ✅         | 📆          |
| `ignore` / skip attribute              | ✅         | ✅          | ✅         | ✅          |
| `no_run` (compile only)                | ✅         | ❌          | ❌         | 🛑          |
| `should_panic`                         | ✅         | ❌          | ❌         | 🛑          |
| Hidden setup lines (`#`)               | ✅         | ❌          | ❌         | 🛑          |
| Output assertions (`// ->`)            | ❌         | ✅ (`iex>`) | ✅ (`>>>`) | 🛑          |
| Module-level doc tests                 | ✅ (`//!`) | ✅          | ✅         | ✅          |
| `compile_fail`                         | ✅         | ❌          | ❌         | 🛑          |
| Multi-target (`erlang` / `javascript`) | ✅ (`cfg`) | ❌          | ❌         | ✅          |
| Incremental / cached generation        | ✅         | ✅          | ✅         | 🛑          |
| Source-mapped error reporting          | ✅         | ✅          | ✅         | ✅          |
