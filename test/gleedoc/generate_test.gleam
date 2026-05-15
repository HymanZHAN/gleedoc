import gleam/list
import gleam/option.{Some}
import gleam/string
import gleedoc/extract.{DocBlock}
import gleedoc/generate
import gleedoc/parse.{CodeBlock}
import simplifile

pub fn generate_single_test_file_test() {
  let doc =
    DocBlock(
      lines: [
        "Adds two numbers.",
        "",
        "```gleam",
        "import math.{add}",
        "let result = add(1, 2)",
        "assert result == 3",
        "```",
      ],
      target: Some("add"),
      file: "src/math.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  let block =
    CodeBlock(
      language: "gleam",
      code: "let result = add(1, 2)\nlet assert True = result == 3",
      source: doc,
      doc_line_offset: 3,
      imports: ["import math.{add}"],
    )

  let config = generate.Config(output_dir: "test")

  let assert Ok(paths) = generate.generate_tests([block], config)
  assert list.length(paths) == 1

  let assert [path] = paths

  let assert Ok(text) = simplifile.read(path)

  assert string.contains(path, "gleedoc")
  assert string.contains(text, "add_1_test")
  assert string.contains(text, "import math.{add}")
  assert string.contains(text, "let result = add(1, 2)")

  // Clean up
  let _ = simplifile.delete(path)
  Nil
}

pub fn generate_test_with_block_imports_test() {
  let doc =
    DocBlock(
      lines: [
        "Example with imports.",
        "",
        "```gleam",
        "import gleam/dict",
        "let d = dict.new()",
        "```",
      ],
      target: Some("example"),
      file: "src/example.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  let block =
    CodeBlock(
      language: "gleam",
      code: "let d = dict.new()",
      source: doc,
      doc_line_offset: 3,
      imports: ["import gleam/dict"],
    )

  let config = generate.Config(output_dir: "test")

  let assert Ok(paths) = generate.generate_tests([block], config)
  assert list.length(paths) == 1

  let assert [path] = paths

  let assert Ok(text) = simplifile.read(path)

  assert string.contains(text, "import gleam/dict")
  assert string.contains(text, "let d = dict.new()")

  // Clean up
  let _ = simplifile.delete(path)
  Nil
}

pub fn generate_test_with_overlapping_block_imports_test() {
  let doc1 =
    DocBlock(
      lines: [
        "Example one.",
        "",
        "```gleam",
        "import gleam/dict",
        "import math.{add}",
        "let result = add(1, 2)",
        "```",
      ],
      target: Some("add"),
      file: "src/math.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  let block1 =
    CodeBlock(
      language: "gleam",
      code: "let result = add(1, 2)",
      source: doc1,
      doc_line_offset: 3,
      imports: ["import gleam/dict", "import math.{add}"],
    )

  let doc2 =
    DocBlock(
      lines: [
        "Example two.",
        "",
        "```gleam",
        "import gleam/dict",
        "import math.{multiply}",
        "let result = multiply(3, 4)",
        "```",
      ],
      target: Some("multiply"),
      file: "src/math.gleam",
      start_line: 10,
      public_names: [],
      module_imports: [],
    )

  let block2 =
    CodeBlock(
      language: "gleam",
      code: "let result = multiply(3, 4)",
      source: doc2,
      doc_line_offset: 3,
      imports: ["import gleam/dict", "import math.{multiply}"],
    )

  let config = generate.Config(output_dir: "test")

  let assert Ok(paths) = generate.generate_tests([block1, block2], config)
  assert list.length(paths) == 1

  let assert [path] = paths

  let assert Ok(text) = simplifile.read(path)

  // gleam/dict was imported by the code snippets but never actually used as
  // `dict.something` in the generated test bodies — the filter removes it.
  let dict_count =
    text
    |> string.split("\n")
    |> list.filter(fn(line) { string.trim(line) == "import gleam/dict" })
    |> list.length
  assert dict_count == 0

  // math imports should be merged into one line with both names
  assert string.contains(text, "import math.{add, multiply}")

  // Clean up
  let _ = simplifile.delete(path)
  Nil
}

/// The generated test file for a source module should automatically include
/// that module's own top-level imports so that doc examples can reference
/// them without re-stating them inside the code snippet.
pub fn generate_includes_source_module_imports_test() {
  // bear.gleam imports gleam/order and gleam/string at the top level.
  // The doc snippet uses `order.Lt` without an explicit import inside the
  // snippet, so the generated file must carry those imports over.
  let doc =
    DocBlock(
      lines: [
        "Compares two bears.",
        "",
        "```gleam",
        "let alpha = Bear(id: 1, name: \"Alpha\", kind: \"Grizzly\", hibernating: False)",
        "let beta  = Bear(id: 2, name: \"Beta\",  kind: \"Polar\",   hibernating: True)",
        "assert order_asc_by_name(alpha, beta) == order.Lt",
        "```",
      ],
      target: Some("order_asc_by_name"),
      file: "test/fixtures/bear.gleam",
      start_line: 1,
      public_names: ["Bear", "order_asc_by_name"],
      module_imports: ["import gleam/order", "import gleam/string"],
    )

  let block =
    CodeBlock(
      language: "gleam",
      code: "let alpha = Bear(id: 1, name: \"Alpha\", kind: \"Grizzly\", hibernating: False)\nlet beta  = Bear(id: 2, name: \"Beta\",  kind: \"Polar\",   hibernating: True)\nassert order_asc_by_name(alpha, beta) == order.Lt",
      source: doc,
      doc_line_offset: 3,
      imports: [],
    )

  let config = generate.Config(output_dir: "test")

  let assert Ok(paths) = generate.generate_tests([block], config)
  let assert [path] = paths

  let assert Ok(text) = simplifile.read(path)

  // The target module itself must be imported (with its public names)
  assert string.contains(text, "import fixtures/bear")
  // gleam/order is carried over and kept because `order.Lt` is referenced
  assert string.contains(text, "import gleam/order")
  // gleam/string is carried over from the source module but filtered out
  // because no test body uses `string.something` — correct behaviour
  assert !string.contains(text, "import gleam/string")
  // The snippet code must appear
  assert string.contains(
    text,
    "assert order_asc_by_name(alpha, beta) == order.Lt",
  )

  // Clean up
  let _ = simplifile.delete(path)
  Nil
}

/// When a code snippet also declares an import that overlaps with a source
/// module import, the two should be merged (not duplicated).
pub fn generate_merges_snippet_and_module_imports_test() {
  // Suppose a snippet explicitly writes `import gleam/order.{Lt}` and the
  // source module already has `import gleam/order`. After merging, only one
  // `import gleam/order` line should appear (with the unqualified name merged).
  let doc =
    DocBlock(
      lines: [
        "Compares two bears.",
        "",
        "```gleam",
        "import gleam/order.{Lt}",
        "let alpha = Bear(id: 1, name: \"Alpha\", kind: \"Grizzly\", hibernating: False)",
        "let beta  = Bear(id: 2, name: \"Beta\",  kind: \"Polar\",   hibernating: True)",
        "assert order_asc_by_name(alpha, beta) == Lt",
        "```",
      ],
      target: Some("order_asc_by_name"),
      file: "test/fixtures/bear.gleam",
      start_line: 1,
      public_names: ["Bear", "order_asc_by_name"],
      module_imports: ["import gleam/order", "import gleam/string"],
    )

  let block =
    CodeBlock(
      language: "gleam",
      code: "let alpha = Bear(id: 1, name: \"Alpha\", kind: \"Grizzly\", hibernating: False)\nlet beta  = Bear(id: 2, name: \"Beta\",  kind: \"Polar\",   hibernating: True)\nassert order_asc_by_name(alpha, beta) == Lt",
      source: doc,
      doc_line_offset: 3,
      imports: ["import gleam/order.{Lt}"],
    )

  let config = generate.Config(output_dir: "test")

  let assert Ok(paths) = generate.generate_tests([block], config)
  let assert [path] = paths

  let assert Ok(text) = simplifile.read(path)

  // gleam/order should appear exactly once
  let order_count =
    text
    |> string.split("\n")
    |> list.filter(fn(line) {
      line |> string.trim |> string.starts_with("import gleam/order")
    })
    |> list.length
  assert order_count == 1

  // The merged line must contain the unqualified name
  assert string.contains(text, "import gleam/order.{Lt}")

  // Clean up
  let _ = simplifile.delete(path)
  Nil
}
