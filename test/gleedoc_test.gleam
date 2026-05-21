import gleedoc
import gleeunit

pub fn main() {
  let config =
    gleedoc.GleedocConfig(
      output_dir: "test/integration",
      source_dir: "dev/fixtures",
      extra_imports: ["gleam/int", "gleam/string"],
      preserve_tests: True,
    )

  config |> gleedoc.run_with(gleeunit.main)
}
