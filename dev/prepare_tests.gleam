import gleedoc

pub fn main() {
  let config =
    gleedoc.GleedocConfig(
      output_dir: "test/integration",
      source_dir: "dev/fixtures",
      extra_imports: ["gleam/int", "gleam/string"],
      preserve_tests: True,
      source_mapped_errors: True,
    )
  let assert Ok(_) = gleedoc.run(config)
}
