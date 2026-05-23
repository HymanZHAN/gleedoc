# API

## `GleedocConfig`

- `source_dir`: The directory containing all the source files. Path resolution is relative to the project root. Default value: `src`.
- `output_dir`: The directory where all the doc tests will be generated. Path resolution is relative to the project root. Default value: `test`.
- `extra_imports`: A list of module names that will automatically be imported in every test. Unused imports will be removed in the final test. Example: `["gleam/int", "gleam/otp/actor"]`.
  - You can see it in action in [`dev/fixture/store.gleam`](dev/fixtures/store.gleam)
- `preserve_tests`: Whether to keep the generated test files in `output_dir` after the test run finishes. Default value: `False`. When using `gleedoc.run_with` together with `gleeunit`, leaving this as `False` keeps your `output_dir` clean between runs. If you are calling `gleedoc.run` programmatically (for example from a `dev/prepare_tests.gleam` script that only generates tests), set this to `True` so the generated files are not deleted afterwards.
- `source_mapped_errors`: Whether to annotate every generated `assert` line with `as "file:line"`, pointing back to the exact source line of the assertion in the original doc comment. Default value: `True`. When enabled, test failures are reported against the original source file/line (e.g. `src/math.gleam:5`) instead of the generated test file. Set to `False` if your snippets place the `assert` somewhere that doesn't fit a single-line `as` annotation well, or if you simply prefer the unannotated output. See the README for the known limitation that motivates this flag.

## `default`

A `gleedoc.default()` helper is provided that returns a `GleedocConfig` with the following defaults:

- `source_dir: "src"`
- `output_dir: "test"`
- `extra_imports: []`
- `preserve_tests: False`
- `source_mapped_errors: True`

You can use it as-is or override individual fields with record update syntax:

```gleam
let config = gleedoc.GleedocConfig(..gleedoc.default(), preserve_tests: True)
```

## `run_with`

Run `gleedoc` with `gleeunit` tests (or any other test functions you want to run).

It takes two arguments: a `GleedocConfig` object and function that will be executed after `gleedoc` generates all the doc tests. Typically, it should be `gleeunit.main`.

```gleam
import gleedoc
import gleeunit

pub fn main() {
  let config =
    gleedoc.GleedocConfig(
      output_dir: "test/integration",
      source_dir: "dev/fixtures",
      extra_imports: ["gleam/int", "gleam/string"],
      preserve_tests: False,
      source_mapped_errors: True,
    )

  config |> gleedoc.run_with(gleeunit.main)
}
```

## `run`

Run `gleedoc` on a project, extracting doc tests from source files and generating test files in the output directory. Typically, you'd want to use this in your own test preparation module:

```gleam
import gleedoc

pub fn main() {
  let config =
    gleedoc.GleedocConfig(
      output_dir: "test/integration",
      source_dir: "dev/fixtures",
      extra_imports: ["gleam/int"],
      preserve_tests: True,
      source_mapped_errors: True,
    )
  let assert Ok(_) = gleedoc.run(config)
}
```
