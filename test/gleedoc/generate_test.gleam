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

  should.be_true(string.contains(text, "gleedoc_add_1_test"))
  should.be_true(string.contains(text, "import math"))
  should.be_true(string.contains(text, "let result = add(1, 2)"))

  // Clean up
  let _ = simplifile.delete(path)
  Nil
}
