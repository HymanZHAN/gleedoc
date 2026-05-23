# gleedoc

[![Package Version](https://img.shields.io/hexpm/v/gleedoc)](https://hex.pm/packages/gleedoc)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gleedoc/)

A **doc test** library for Gleam, inspired by Rust and Elixir's doctest tooling.

Doc tests let you write executable examples in your documentation comments (`///`). These examples are extracted, compiled, and run as part of your test suite, ensuring your documentation never goes out of date.

> 🚩 Disclaimer: This project contains substantial LLM-generated code, and I used LLMs for research and design. But I (as a Gleam amateur) have tried my best to review all the code line by line, adjust, and refactor.

## Installation

```sh
gleam add gleedoc --dev
```

## Usage

### Integration with `gleeunit`

In your test entry file `test/<your_project>_test.gleam`, you can provide a `GleedocConfig` and use it with the `gleedoc.run_with` function. Take [`gleedoc_test.gleam`](./test/gleedoc_test.gleam) for example:

```gleam
import gleedoc
import gleeunit

pub fn main() {
  gleedoc.default() |> gleedoc.run_with(gleeunit.main)
}
```

`gleedoc.default` is a helper function that returns a default `GleedocConfig`. After the configuration is in place, you can run your tests as usual:

```sh
gleam test
```

The corresponding doc tests will be first generated in `<output_dir>/gleedoc` and then be executed as part of the test run.

If a doc test fails, you can navigate to the corresponding doc block via the `info` in the terminal output:

```text
assert test/integration/gleedoc/fixtures_example_gleedoc_test.gleam:9
 test: integration@gleedoc@fixtures_example_gleedoc_test.add_1_test
 code: assert result == 5
 left: 3
right: literal
 info: dev/fixtures/example.gleam:6  👈
```

For more details about the exposed functions and types, please refer to [API](./doc/API.md).

For more ways to use `gleedoc` (e.g. running it programmatically), please refer to [USAGE](./doc/USAGE.md).

### Caveats

#### Duplicate terminal output

Gleam is a compiled language, and that means `gleam test` will need to compile all tests first before invoking `<your_project>_test.gleam`'s `main` function. Due to this limitation, `gleedoc.run_with` will actually generate the latest doc tests **and then** spawn another `gleam test` command to actually run the tests (credits to [testament](https://github.com/bwireman/testament) for working this out). Therefore, the terminal output might look a bit funny:

```text
> gleam test
   Compiled in 0.02s
    Running gleedoc_test.main
   Compiled in 0.02s          # <- duplicate output
    Running gleedoc_test.main # <- duplicate output
.............................................................................................................................
125 passed, no failures
```

#### `assert` on a single line

When doing assertion in code blocks in doc comments, the `assert` needs to be on a single line.

For example, this will not work:

````gleam
/// ```gleam
/// assert
///   range(from: 0, to: 3, with: "", run: fn(acc, i) {
///     acc <> to_string(i)
///   })
///   == "012"
/// ```
````

It needs to be rewritten as:

````gleam
/// ```gleam
/// let outcome =
///   range(from: 0, to: 3, with: "", run: fn(acc, i) {
///     acc <> to_string(i)
///   })
/// assert outcome == "012"
/// ```
````

This is because in the first example, it's hard to decide where to put the `as` clause for source-mapped error reporting. For simplicity, the current implementation just puts the `as` clause at the end of the `assert` line. This is a known limitation and might be enhanced in the future.

## How it works

1. **Extract** `///` doc comments from your `.gleam` source files.
2. **Find** fenced code blocks tagged with `gleam` inside those comments.
3. **Generate** test modules from gleam code blocks in your `test/` directory.
4. **Run** the generated tests with `gleam test`.

### `import` resolution

Each generated test file receives imports from four sources, merged and deduplicated automatically:

1. **The source module's own top-level imports** — any `import` statements at the top of the source file are carried over, so your snippets can use the same types and helpers the module itself uses without restating them.
2. **Imports written inside the code block** — you can always add an explicit `import` line inside a snippet for anything extra.
3. **The source module itself** — `gleedoc` scans the module's public names with `glance` and generates a list of unqualified imports that include **all** public functions/types/constants, so you can call functions directly in your snippets.
4. **The `GleedocConfig`'s `extra_imports`**

For example, given this source file `src/user.gleam`:

````gleam
import gleam/option.{type Option}              // 1️⃣

/// Returns a greeting for the user.
///
/// ```gleam
/// import gleam/option.{Some}                 // 2️⃣
///
/// let name = Some("Alice")
/// assert greet(name) == "Hello, Alice!"
///
/// let assert [greet, ..] = string.split(greet(name), ",")
/// assert greet == "Hello"
/// ```
pub fn greet(name: Option(String)) -> String { // 3️⃣
  name
  |> option.map(fn(n) { "Hello, " <> n <> "!" })
  |> option.unwrap("")
}
````

And the following `GleedocConfig`:

```gleam
let config = gleedoc.GleedocConfig(
  source_dir: "src",
  output_dir: "test",
  extra_imports: ["gleam/string"], // 4️⃣
  preserve_tests: True,
)
```

The generated `user_gleedoc_test.gleam` will contain imports merged from all three sources:

```gleam
// Generated by gleedoc - do not edit manually

import gleam/option.{Some}  // 1️⃣ + 2️⃣
import gleam/string         // 4️⃣
import user.{greet}         // 3️⃣

// From: src/user.gleam:5
pub fn greet_1_test() {
  let name = Some("Alice")
  assert greet(name) == "Hello, Alice!" as "src/user.gleam:5"

  let assert [greet, ..] = string.split(greet(name), ",")
  assert greet == "Hello" as "src/user.gleam:5"
}
```

If the same module is imported in multiple places (e.g. `gleam/option` appears in both the source file's import and the code block in comment), the unqualified names from all of them are merged into a single import line. Unused imports in the generated tests will be removed (e.g. `gleam/option.{type Option}`).

The `import` resolution should be sufficient in most cases. If not, you can add the required imports in the code block, or configure `extra_imports` in `GleedocConfig`.

## Development

```sh
gleam test
```

You can also run the tests with the JavaScript target:

```sh
gleam test -t javascript
```

### Windows

On Windows, you probably want to make sure that `autocrlf` is false **before** checking out this repo:

```sh
git config --global core.autocrlf false
```

`gleam format` always format with the `\n` line break, so checking out with `\r\n` is not ideal.

### Contributing

Please kindly create an issue in your human voice, clearly describe the feature request or bug with reproduction steps, and ideally include a proposed solution **before** creating any PR.

### Roadmap

See [ROADMAP](./doc/ROADMAP.md)

## Prior art

- **[testament](https://github.com/bwireman/testament)** — another Gleam doc test library that pioneered the env-var-guarded re-invocation of `gleam test` to work around the CLI's limitation. Gleedoc's `run_with` follows the same pattern, and the project is better for it. Thank you @bwireman!

## The name

`gleeunit` for **unit** tests, `gleedoc` for **doc** tests! 😸
