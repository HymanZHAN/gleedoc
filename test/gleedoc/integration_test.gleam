import gleam/list
import gleam/string
import gleedoc
import gleedoc/generate
import simplifile

pub fn clean_generated_test() {
  // Create a fake generated file
  let _ = simplifile.create_directory_all("test/gleedoc")
  let fake_path = "test/gleedoc/gleedoc_generated_fake_test.gleam"
  let _ = simplifile.write(fake_path, "// fake")

  let assert Ok(_) = generate.clean_generated("test")

  // Verify it's gone
  let exists = simplifile.is_file(fake_path)
  case exists {
    Ok(True) -> panic as "Expected file to be deleted"
    _ -> Nil
  }
}
