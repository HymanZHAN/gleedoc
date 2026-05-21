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

pub fn ignore_blocks_with_ignore_attribute_test() {
  let doc =
    DocBlock(
      lines: [
        "With ignored block.",
        "",
        "```gleam,ignore",
        "let a = 1",
        "```",
        "",
        "```gleam",
        "let b = 2",
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
  assert block.code == "let b = 2"
}

pub fn other_attributes_are_kept_but_do_not_skip_test() {
  let doc =
    DocBlock(
      lines: [
        "```gleam,no_run",
        "let a = 1",
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
  assert block.attributes == ["no_run"]
  assert block.code == "let a = 1"
}

pub fn ignore_among_multiple_attributes_test() {
  let doc =
    DocBlock(
      lines: [
        "```gleam,no_run,ignore",
        "let a = 1",
        "```",
      ],
      target: Some("foo"),
      file: "src/foo.gleam",
      start_line: 1,
      public_names: [],
      module_imports: [],
    )

  assert parse.extract_gleam_blocks([doc]) == []
}
