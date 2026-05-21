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

pub fn default_config_test() {
  let config = gleedoc.default()

  assert config.source_dir == "src"
  assert config.output_dir == "test"
  assert config.extra_imports == []
  assert config.preserve_tests == False
}
