# Gleedoc: A Doc Test Library for Gleam

## How Other Languages Do It

### Rust
- Doc comments (`///`) can contain fenced code blocks (```` ```rust ````)
- `cargo test` extracts these blocks, wraps them in a test harness, compiles and runs them
- Code blocks are treated as standalone Rust programs that can use `assert!`, `assert_eq!`, etc.
- Attributes control behavior: `no_run` (compile only), `ignore` (skip), `should_panic`
- The doctest runner links against the crate being tested, so all public APIs are available

### Elixir
- `@doc` module attributes hold markdown documentation
- `iex>` prompts in code blocks are extracted by `ExUnit.DocTest`
- The REPL-style input/output format is parsed: `iex> expr` followed by expected output
- ExUnit runs each expression and compares the inspected result with the expected output
- Built into the standard test framework via `doctest ModuleName`

### Python
- Docstrings (triple-quoted strings on modules/classes/functions) contain `>>>` interactive prompt examples
- The `doctest` module in the stdlib parses these, executes the code, and compares output
- Very REPL-oriented, similar to Elixir but for Python's interactive prompt

## Proposed Approach for Gleam

### Why Gleam is Different
1. **No REPL**: Unlike Elixir and Python, Gleam has no built-in REPL. We cannot evaluate expressions interactively.
2. **Compiled Language**: Like Rust, Gleam is compiled. Code blocks must be compiled and executed.
3. **Doc Comments**: Gleam uses `///` for documentation comments, which the compiler strips and stores in module interfaces.
4. **No Runtime Reflection**: We cannot easily query doc comments at runtime from compiled modules.

### Architecture

#### Phase 1: Source Parsing & Extraction
Since `glance` (the Gleam parser in Gleam) does **not** preserve doc comments in its AST, we will parse source files manually:

1. **Scan `.gleam` source files** line by line
2. **Extract `///` comment blocks** — consecutive lines starting with `///`
3. **Associate comments with definitions** — track the next non-comment, non-blank line to know which function/type/constant the docs belong to
4. **Parse markdown** within doc comments to find ````gleam` fenced code blocks

#### Phase 2: Code Block Processing
Each ````gleam` code block becomes a candidate doctest:

```markdown
/// Adds two numbers together.
///
/// ```gleam
/// let result = add(1, 2)
/// assert result == 3
/// ```
pub fn add(a: Int, b: Int) -> Int { a + b }
```

The extracted code block is treated as the body of a generated test function.

#### Phase 3: Test Generation
Generate a temporary test module (`test/gleedoc_generated_*.gleam`) containing:
- Imports from the original module(s)
- One test function per doc block
- The verbatim code from the block as the test body

```gleam
// test/gleedoc_generated_mymodule.gleam
import mymodule
import gleeunit/should

pub fn mymodule_add_doctest_1_test() {
  let result = mymodule.add(1, 2)
  assert result == 3
}
```

#### Phase 4: Execution
Run the generated tests via `gleam test` (or integrate with `gleeunit`).

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| Source-based extraction | Gleam's compiled `.cache` metadata is binary and inaccessible from Gleam code |
| `glance` for structural context | Use `glance` to parse the module and understand which definitions exist, then match doc blocks to them by position |
| Manual line-based comment extraction | `glance` discards comments; we need raw source scanning for `///` |
| Generated test files | Gleam requires compilation; we must generate real `.gleam` test files |
| No REPL-style `>` prompts | Gleam has no REPL; raw code blocks are more natural |
| Panic = failure | A code block that panics fails the doctest, matching Rust semantics |
| Assertion libraries optional | Users can use `let assert`, `should.equal`, or any assertion style |

### Relevant Hex Packages

| Package | Purpose |
|---------|---------|
| `glance` (v6.0.0) | Parse Gleam source to understand module structure (functions, types, constants). Used to verify extracted doc blocks map to real definitions. |
| `gleeunit` | Standard test runner; our generated tests are compatible with it |
| `simplifile` (v2.x) | Cross-target file I/O for reading source files and writing generated tests |
| `glob` (v1.x) | Match `src/**/*.gleam` files to find all source files |
| `snag` (v1.x) | Lightweight error handling for extraction/parse failures |
| `gleam_json` (v3.x) | If we later want to output machine-readable results |

### Milestones

1. **MVP**: Extract `///` doc comments and ````gleam` blocks from a single file, generate one test file, run via `gleam test`
2. **Multi-file**: Walk `src/` recursively, process all `.gleam` files
3. **Definition association**: Use `glance` to match doc blocks to specific functions/types and report failures with source locations
4. **Attributes**: Support `// gleedoc: ignore` and `// gleedoc: no_run` annotations within code blocks
5. **Integration**: Provide a `gleedoc.run()` function that can be called from `test/gleedoc_test.gleam`
6. **Output assertions**: Support `// -> "expected output"` for comparing `io.println` output
7. **CLI tool**: Wrap everything in a `gleam run -m gleedoc` experience
