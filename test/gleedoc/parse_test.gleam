import gleam/list
import gleam/option.{None, Some}
import gleedoc/extract.{DocBlock}
import gleedoc/parse
import gleeunit/should

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
    )

  let blocks = parse.extract_code_blocks([doc])
  should.equal(list.length(blocks), 1)

  let block = case blocks {
    [b] -> b
    _ -> panic as "Expected exactly one code block"
  }

  should.equal(block.language, "gleam")
  should.equal(block.code, "let result = add(1, 2)")
  should.equal(block.source.target, Some("add"))
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
    )

  let blocks =
    parse.extract_code_blocks([doc])
    |> parse.gleam_blocks

  should.equal(list.length(blocks), 1)

  let block = case blocks {
    [b] -> b
    _ -> panic as "Expected exactly one gleam block"
  }

  should.equal(block.language, "gleam")
}

pub fn no_code_blocks_test() {
  let doc =
    DocBlock(
      lines: ["Just some docs without code."],
      target: None,
      file: "src/foo.gleam",
      start_line: 1,
    )

  let blocks = parse.extract_code_blocks([doc])
  should.equal(list.length(blocks), 0)
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
    )

  let blocks = parse.extract_code_blocks([doc])
  should.equal(list.length(blocks), 2)
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
    )

  let blocks = parse.extract_code_blocks([doc])
  should.equal(list.length(blocks), 1)

  let block = case blocks {
    [b] -> b
    _ -> panic as "Expected exactly one code block"
  }

  should.equal(block.imports, ["import gleam/dict", "import gleam/http"])
  should.equal(block.code, "\nlet d = dict.new()")
}
