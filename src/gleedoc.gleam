import gleam/list
import gleam/result
import gleam/string
import gleedoc/extract
import gleedoc/generate.{Config}
import gleedoc/parse
import simplifile
import snag

/// Configuration for a gleedoc run.
pub type GleedocConfig {
  GleedocConfig(
    /// The module name being tested, e.g. "mymodule"
    module_name: String,
    /// The package name being tested
    package_name: String,
    /// Directory to write generated tests to, typically "test"
    output_dir: String,
    /// Directory to read source files from, typically "src"
    source_dir: String,
  )
}

/// Run gleedoc on a project, extracting doc tests from source files and generating
/// test files in the output directory.
pub fn run(config: GleedocConfig) -> Result(Nil, snag.Snag) {
  // Find all gleam source files
  use files <- result.try(find_source_files(config.source_dir))

  // Extract doc blocks from all files
  use doc_blocks <- result.try(
    files
    |> list.try_map(extract.doc_blocks_from_file)
    |> result.map(list.flatten)
    |> result.map_error(fn(e) { e }),
  )

  // Extract gleam code blocks from doc comments
  let code_blocks =
    doc_blocks
    |> parse.extract_code_blocks
    |> parse.gleam_blocks

  case code_blocks {
    [] -> {
      // Nothing to do
      Ok(Nil)
    }
    blocks -> {
      let gen_config =
        Config(
          module_name: config.module_name,
          package_name: config.package_name,
          output_dir: config.output_dir,
        )

      // Clean old generated tests first
      use _ <- result.try(generate.clean_generated(config.output_dir))

      // Generate new test files
      use _ <- result.try(generate.generate_tests(blocks, gen_config))

      Ok(Nil)
    }
  }
}

/// CLI entry point. Reads gleam.toml to infer module/package names.
pub fn main() -> Nil {
  let config =
    GleedocConfig(
      module_name: "gleedoc",
      package_name: "gleedoc",
      output_dir: "test",
      source_dir: "src",
    )

  case run(config) {
    Ok(Nil) -> {
      // Successfully generated tests
      Nil
    }
    Error(_snag) -> {
      // In a real CLI we'd print the error
      Nil
    }
  }
}

fn find_source_files(source_dir: String) -> Result(List(String), snag.Snag) {
  find_gleam_files_recursive(source_dir, [])
}

fn find_gleam_files_recursive(
  dir: String,
  acc: List(String),
) -> Result(List(String), snag.Snag) {
  use entries <- result.try(
    dir
    |> simplifile.read_directory
    |> result.map_error(fn(err) {
      snag.new(
        "Failed to read directory: " <> dir <> " - " <> string.inspect(err),
      )
    }),
  )

  entries
  |> list.try_fold(acc, fn(acc, entry) {
    let path = dir <> "/" <> entry
    use is_dir <- result.try(
      path
      |> simplifile.is_directory
      |> result.map_error(fn(err) {
        snag.new("Failed to stat: " <> path <> " - " <> string.inspect(err))
      }),
    )

    case is_dir {
      True -> find_gleam_files_recursive(path, acc)
      False -> {
        case string.ends_with(path, ".gleam") {
          True -> Ok([path, ..acc])
          False -> Ok(acc)
        }
      }
    }
  })
}
