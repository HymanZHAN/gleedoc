import gleam/list
import gleam/string
import gleedoc
import gleedoc/generate
import simplifile

pub fn full_pipeline_test() {
  // Run gleedoc on the example module
  let config =
    gleedoc.GleedocConfig(output_dir: "test", source_dir: "test/fixtures")

  let assert Ok(_) = gleedoc.run(config)

  // Find any generated test files
  let assert Ok(all_files) = simplifile.read_directory("test/doc_test")
  let generated_files =
    all_files
    |> list.filter(string.starts_with(_, "gleedoc_"))
    |> list.filter(string.ends_with(_, "_test.gleam"))

  assert generated_files != []

  // Clean up any generated files
  list.each(generated_files, fn(f) {
    let _ = simplifile.delete("test/doc_test/" <> f)
    Nil
  })
}

pub fn clean_generated_test() {
  // Create a fake generated file
  let _ = simplifile.create_directory_all("test/doc_test")
  let fake_path = "test/doc_test/gleedoc_generated_fake_test.gleam"
  let _ = simplifile.write(fake_path, "// fake")

  let assert Ok(_) = generate.clean_generated("test")

  // Verify it's gone
  let exists = simplifile.is_file(fake_path)
  case exists {
    Ok(True) -> panic as "Expected file to be deleted"
    _ -> Nil
  }
}
