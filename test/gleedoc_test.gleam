import gleam/list
import gleam/string
import gleedoc
import gleeunit

pub fn main() {
  let config =
    gleedoc.GleedocConfig(
      output_dir: "test/integration",
      source_dir: "dev/fixtures",
      extra_imports: ["gleam/int", "gleam/string"],
      preserve_tests: True,
      source_mapped_errors: True,
    )

  config |> gleedoc.run_with(gleeunit.main)
}

pub fn default_config_test() {
  let config = gleedoc.default()

  assert config.source_dir == "src"
  assert config.output_dir == "test"
  assert config.extra_imports == []
  assert config.preserve_tests == False
  assert config.source_mapped_errors == True
}

pub fn new_matches_default_test() {
  assert gleedoc.new() == gleedoc.default()
}

pub fn with_extra_imports_replaces_list_test() {
  let config =
    gleedoc.new()
    |> gleedoc.add_extra_import("gleam/int")
    |> gleedoc.with_extra_imports(["gleam/string", "gleam/list"])

  // `with_extra_imports` replaces the whole list, so the earlier
  // `add_extra_import` call is overwritten. Compare order-independently.
  assert list.sort(config.extra_imports, string.compare)
    == ["gleam/list", "gleam/string"]
}

pub fn builder_pipeline_test() {
  let config =
    gleedoc.new()
    |> gleedoc.with_source_dir("dev/fixtures")
    |> gleedoc.with_output_dir("test/integration")
    |> gleedoc.add_extra_import("gleam/int")
    |> gleedoc.add_extra_import("gleam/string")
    |> gleedoc.with_preserve_tests(True)
    |> gleedoc.with_source_mapped_errors(True)

  // The builder pipeline should produce the same scalar fields as the
  // explicit record construction used in `main` above. `extra_imports` is
  // compared order-independently.
  assert config.source_dir == "dev/fixtures"
  assert config.output_dir == "test/integration"
  assert config.preserve_tests == True
  assert config.source_mapped_errors == True
  assert list.sort(config.extra_imports, string.compare)
    == ["gleam/int", "gleam/string"]
}
