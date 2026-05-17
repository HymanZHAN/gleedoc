import gleam/list
import gleam/option.{None, Some}
import gleedoc/extract.{DocBlock}
import gleedoc/parse

pub fn extract_gleam_code_block_test() {
  let doc =
    DocBlock(
      lines: [
        "Adds two numbers.",
        "",
        "```gleam",
        "let result = add(1, 2)",
        "```",
      ],
      target: Some("add"),
      file: "src/math.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  let blocks = parse.extract_gleam_blocks([doc])
  assert list.length(blocks) == 1

  let assert [block] = blocks

  assert block.language == "gleam"
  assert block.code == "let result = add(1, 2)"
  assert block.source.target == Some("add")
}

pub fn ignore_non_gleam_blocks_test() {
  let doc =
    DocBlock(
      lines: [
        "Some docs.",
        "",
        "```javascript",
        "console.log(1)",
        "```",
        "",
        "```gleam",
        "let x = 1",
        "```",
      ],
      target: Some("foo"),
      file: "src/foo.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  let blocks = parse.extract_gleam_blocks([doc])

  assert list.length(blocks) == 1

  let assert [block] = blocks

  assert block.language == "gleam"
}

pub fn no_code_blocks_test() {
  let doc =
    DocBlock(
      lines: ["Just some docs without code."],
      target: None,
      file: "src/foo.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  let blocks = parse.extract_gleam_blocks([doc])
  assert blocks == []
}

pub fn multiple_code_blocks_test() {
  let doc =
    DocBlock(
      lines: [
        "Examples.",
        "",
        "```gleam",
        "let a = 1",
        "```",
        "",
        "```gleam",
        "let b = 2",
        "```",
      ],
      target: Some("example"),
      file: "src/example.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  let blocks = parse.extract_gleam_blocks([doc])
  assert list.length(blocks) == 2
}

pub fn extract_imports_from_code_block_test() {
  let doc =
    DocBlock(
      lines: [
        "Example with imports.",
        "",
        "```gleam",
        "import gleam/dict",
        "import gleam/http",
        "",
        "let d = dict.new()",
        "```",
      ],
      target: Some("example"),
      file: "src/example.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  let blocks = parse.extract_gleam_blocks([doc])
  assert list.length(blocks) == 1

  let assert [block] = blocks

  assert block.imports == ["import gleam/dict", "import gleam/http"]
  assert block.code == "\nlet d = dict.new()"
}
