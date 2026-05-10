# Changelog

## v0.1.0-rc — 2026-05-10

Initial release.

- Extract `///` doc comments from Gleam source files.
- Parse fenced ` ```gleam ` code blocks inside doc comments.
- Generate `gleeunit`-compatible test files in the `test/` directory.
- Multi-file source discovery via recursive directory scanning.
- `glance`-powered public name extraction for unqualified imports in generated tests.
- CLI entry point via `gleam run -m gleedoc`.
