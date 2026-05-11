import gleam/list
import gleam/option.{None, Some}
import gleedoc/extract

const fixture = "test/fixtures/example.gleam"

pub fn extract_from_real_example_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  assert list.length(blocks) == 4
}

pub fn extract_block_targets_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  let targets = list.map(blocks, fn(b) { b.target })

  assert targets == [Some("add"), Some("multiply"), Some("greet"), Some("find")]
}

pub fn extract_block_start_lines_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  let start_lines = list.map(blocks, fn(b) { b.start_line })
  assert start_lines == [4, 14, 24, 38]
}

pub fn extract_block_file_path_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  list.each(blocks, fn(b) {
    assert b.file == fixture
  })
}

pub fn extract_add_block_lines_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  let assert [add_block, ..] = blocks

  assert add_block.target == Some("add")
  assert add_block.lines
    == [
      "A simple example module demonstrating gleedoc.",
      "",
      "```gleam",
      "let result = add(1, 2)",
      "let assert True = result == 3",
      "```",
    ]
}

pub fn extract_multiply_block_lines_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  let assert [_, multiply_block, ..] = blocks

  assert multiply_block.target == Some("multiply")
  assert multiply_block.lines
    == [
      "Multiply two numbers.",
      "",
      "```gleam",
      "let result = multiply(3, 4)",
      "let assert True = result == 12",
      "```",
    ]
}

pub fn extract_greet_block_lines_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  let assert [_, _, greet_block, ..] = blocks

  assert greet_block.target == Some("greet")
  assert greet_block.lines
    == [
      "Greet a user by name.",
      "",
      "```gleam",
      "let msg = greet(\"Alice\")",
      "let assert True = msg == \"Hello, Alice!\"",
      "```",
    ]
}

pub fn extract_find_block_lines_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  let assert [_, _, _, find_block] = blocks

  assert find_block.target == Some("find")
  assert find_block.start_line == 38
  assert find_block.lines
    == [
      "Find a user by user ID.",
      "",
      "```gleam",
      "let john = User(\"John\", \"Doe\")",
      "let bill = User(\"Bill\", \"Wilson\")",
      "",
      "let users =",
      "[#(\"bill_wilson\", bill), #(\"john_doe\", john)]",
      "|> dict.from_list",
      "",
      "assert users |> find(\"hello\") == User(\"\", \"\")",
      "assert users |> find(\"john_doe\") == john",
      "```",
    ]
}

pub fn extract_no_doc_for_undocumented_type_test() {
  let assert Ok(blocks) = extract.doc_blocks_from_file(fixture)

  // The `User` type has no doc comment, so it must not appear as a target.
  let targets = list.map(blocks, fn(b) { b.target })

  assert !list.contains(targets, Some("User"))
  assert !list.contains(targets, None)
}
