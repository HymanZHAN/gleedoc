import gleedoc
import gleeunit

pub fn main() {
  let config =
    gleedoc.GleedocConfig(
      output_dir: "test/integration",
      source_dir: "test/fixtures",
    )

  let assert Ok(_) = gleedoc.run(config)
  gleeunit.main()
}
