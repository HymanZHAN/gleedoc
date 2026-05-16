import gleedoc

pub fn main() {
  let config =
    gleedoc.GleedocConfig(
      output_dir: "test/integration",
      source_dir: "dev/fixtures",
      preludes: ["gleam/int"],
    )
  let assert Ok(_) = gleedoc.run(config)
}
