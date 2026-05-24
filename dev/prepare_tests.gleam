import gleedoc

pub fn main() {
  gleedoc.new()
  |> gleedoc.with_source_dir("dev/fixtures")
  |> gleedoc.with_output_dir("test/integration")
  |> gleedoc.with_extra_imports(["gleam/int", "gleam/string"])
  |> gleedoc.with_preserve_tests(True)
  |> gleedoc.run()
}
