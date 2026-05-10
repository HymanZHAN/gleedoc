import gleam/list
import gleam/option.{Some}
import gleam/string
import gleedoc/extract.{DocBlock}
import gleedoc/generate
import gleedoc/parse.{CodeBlock}
import gleeunit/should
import simplifile

pub fn generate_single_test_file_test() {
  let doc =
    DocBlock(
      lines: [
        "Adds two numbers.",
        "",
        "```gleam",
        "let result = add(1, 2)",
        "let assert True = result == 3",
        "```",
      ],
      target: Some("add"),
      file: "src/math.gleam",
      start_line: 1,
    )

  let block =
    CodeBlock(
      language: "gleam",
      code: "let result = add(1, 2)\nlet assert True = result == 3",
      source: doc,
      doc_line_offset: 3,
      imports: [],
    )

  let config = generate.Config(output_dir: "test")

  let result = generate.generate_tests([block], config)
  let paths = should.be_ok(result)
  should.equal(list.length(paths), 1)

  let path = case paths {
    [p] -> p
    _ -> panic as "Expected one path"
  }

  let content = simplifile.read(path)
  let text = should.be_ok(content)

  should.be_true(string.contains(path, "doc_test"))
  should.be_true(string.contains(text, "gleedoc_add_1_test"))
  should.be_true(string.contains(text, "import math"))
  should.be_true(string.contains(text, "let result = add(1, 2)"))

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

  let result = generate.generate_tests([block], config)
  let paths = should.be_ok(result)
  should.equal(list.length(paths), 1)

  let path = case paths {
    [p] -> p
    _ -> panic as "Expected one path"
  }

  let content = simplifile.read(path)
  let text = should.be_ok(content)

  should.be_true(string.contains(text, "import gleam/dict"))
  should.be_true(string.contains(text, "let d = dict.new()"))

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

  let result = generate.generate_tests([block1, block2], config)
  let paths = should.be_ok(result)
  should.equal(list.length(paths), 1)

  let path = case paths {
    [p] -> p
    _ -> panic as "Expected one path"
  }

  let content = simplifile.read(path)
  let text = should.be_ok(content)

  // gleam/dict should appear only once
  let dict_count =
    text
    |> string.split("\n")
    |> list.filter(fn(line) { string.trim(line) == "import gleam/dict" })
    |> list.length
  should.equal(dict_count, 1)

  // math imports should be merged into one line
  should.be_true(string.contains(text, "import math.{add, multiply}"))

  // Clean up
  let _ = simplifile.delete(path)
  Nil
}
