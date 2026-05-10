import gleam/list
import gleam/option.{Some}
import gleam/string
import gleeunit/should
import gleedoc/extract
import simplifile

const test_file = "test/fixtures/sample.gleam"

fn setup_test_file(content: String) {
  let _ = simplifile.create_directory("test/fixtures")
  let _ = simplifile.write(test_file, content)
  Nil
}

fn cleanup_test_file() {
  let _ = simplifile.delete(test_file)
  Nil
}

pub fn extract_single_function_doc_test() {
  setup_test_file(
    "/// Adds two numbers.\n"
    <> "///\n"
    <> "/// ```gleam\n"
    <> "/// let result = add(1, 2)\n"
    <> "/// ```\n"
    <> "pub fn add(a: Int, b: Int) -> Int {\n"
    <> "  a + b\n"
    <> "}\n",
  )

  let result = extract.doc_blocks_from_file(test_file)
  cleanup_test_file()

  let blocks = should.be_ok(result)
  should.equal(list.length(blocks), 1)

  let block = case blocks {
    [b] -> b
    _ -> panic as "Expected exactly one doc block"
  }

  should.equal(block.target, Some("add"))
  should.equal(block.file, test_file)
  should.equal(block.start_line, 1)

  // Check that lines have /// stripped
  let first_line = case block.lines {
    [first, ..] -> first
    [] -> panic as "Expected at least one line"
  }
  should.be_true(string.contains(first_line, "Adds two numbers"))
}

pub fn extract_multiple_docs_test() {
  setup_test_file(
    "/// First function.\n"
    <> "pub fn one() -> Int { 1 }\n"
    <> "\n"
    <> "/// Second function.\n"
    <> "pub fn two() -> Int { 2 }\n",
  )

  let result = extract.doc_blocks_from_file(test_file)
  cleanup_test_file()

  let blocks = should.be_ok(result)
  should.equal(list.length(blocks), 2)

  let targets = list.map(blocks, fn(b) { b.target })
  should.be_true(list.contains(targets, Some("one")))
  should.be_true(list.contains(targets, Some("two")))
}

pub fn extract_type_doc_test() {
  setup_test_file(
    "/// A user in the system.\n"
    <> "pub type User {\n"
    <> "  User(name: String)\n"
    <> "}\n",
  )

  let result = extract.doc_blocks_from_file(test_file)
  cleanup_test_file()

  let blocks = should.be_ok(result)
  should.equal(list.length(blocks), 1)

  let block = case blocks {
    [b] -> b
    _ -> panic as "Expected exactly one doc block"
  }

  should.equal(block.target, Some("User"))
}

pub fn extract_const_doc_test() {
  setup_test_file(
    "/// The answer.\n"
    <> "pub const answer = 42\n",
  )

  let result = extract.doc_blocks_from_file(test_file)
  cleanup_test_file()

  let blocks = should.be_ok(result)
  should.equal(list.length(blocks), 1)

  let block = case blocks {
    [b] -> b
    _ -> panic as "Expected exactly one doc block"
  }

  should.equal(block.target, Some("answer"))
}
