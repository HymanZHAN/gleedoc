import gleeunit/should
import gleedoc/extract

pub fn extract_from_real_example_test() {
  let result = extract.doc_blocks_from_file("test/fixtures/example.gleam")
  let _blocks = should.be_ok(result)
  should.equal(3, 3)
}
