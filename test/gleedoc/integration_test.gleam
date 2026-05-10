import gleam/list
import gleam/string
import gleedoc
import gleedoc/generate
import gleeunit/should
import simplifile

pub fn full_pipeline_test() {
  // Run gleedoc on the example module
  let config =
    gleedoc.GleedocConfig(output_dir: "test", source_dir: "test/fixtures")

  let result = gleedoc.run(config)
  should.be_ok(result)

  // Find any generated test files
  let files = simplifile.read_directory("test")
  let all_files = should.be_ok(files)
  let generated_files =
    list.filter(all_files, fn(f) {
      string.starts_with(f, "gleedoc_generated_")
      && string.ends_with(f, "_test.gleam")
    })

  should.be_true(generated_files != [])

  // Clean up any generated files
  list.each(generated_files, fn(f) {
    let _ = simplifile.delete("test/" <> f)
    Nil
  })
}

pub fn clean_generated_test() {
  // Create a fake generated file
  let fake_path = "test/gleedoc_generated_fake_test.gleam"
  let _ = simplifile.write(fake_path, "// fake")

  let result = generate.clean_generated("test")
  should.be_ok(result)

  // Verify it's gone
  let exists = simplifile.is_file(fake_path)
  case exists {
    Ok(True) -> panic as "Expected file to be deleted"
    _ -> Nil
  }
}
