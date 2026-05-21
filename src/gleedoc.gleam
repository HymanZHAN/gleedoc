import argv
import envoy
import filepath
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleedoc/extract
import gleedoc/generate.{Config}
import gleedoc/parse
import shellout.{LetBeStderr, LetBeStdout, SetEnvironment}
import simplifile
import snag

/// Environment variable used to detect whether the current `gleam test`
/// invocation is the initial test-generation pass (set) or the inner
/// invocation that should actually compile and execute the tests (unset).
const test_generation_running = "GLEEDOC_GENERATION_RUNNING"

/// Configuration for a gleedoc run.
pub type GleedocConfig {
  GleedocConfig(
    /// A list of imports that will automatically be applied to every generated test file.
    /// Example: `["gleam/int", "gleam/otp/actor"]`
    extra_imports: List(String),
    /// Directory to read source files from, typically "src"
    source_dir: String,
    /// Directory to write generated tests to, typically "test"
    output_dir: String,
  )
}

/// CLI entry point
pub fn main() -> Nil {
  let config =
    GleedocConfig(output_dir: "test", source_dir: "src", extra_imports: [])

  case run(config) {
    Ok(Nil) -> Nil
    Error(snag) -> panic as snag.issue
  }
}

/// Run gleedoc on a project, extracting doc tests from source files and generating
/// test files in the output directory.
pub fn run(config: GleedocConfig) -> Result(Nil, snag.Snag) {
  // Find all gleam source files
  use files <- result.try(find_gleam_files(config.source_dir))

  // Extract doc blocks from all files
  use doc_blocks <- result.try(
    files
    |> list.try_map(extract.doc_blocks_from_file)
    |> result.map(list.flatten),
  )

  // Extract gleam code blocks from doc comments
  let code_blocks = parse.extract_gleam_blocks(doc_blocks)

  case code_blocks {
    [] -> {
      // Nothing to do
      Ok(Nil)
    }
    blocks -> {
      let gen_config =
        Config(
          output_dir: config.output_dir,
          extra_imports: config.extra_imports,
        )

      // Clean old generated tests first
      use _ <- result.try(generate.clean_generated(config.output_dir))

      // Generate new test files
      use _ <- result.try(generate.generate_tests(blocks, gen_config))

      // Format new test files
      use _ <- result.try(generate.format_tests(config.output_dir))

      Ok(Nil)
    }
  }
}

/// Run gleedoc and then execute the project's tests.
///
/// Because `gleam test` does not pick up newly-generated test files within the
/// same compilation, this function uses a two-pass strategy controlled by the
/// `GLEEDOC_GENERATION_RUNNING` environment variable:
///
/// 1. First pass (env var unset): generate the test files, set the env var,
///    then re-invoke `gleam test` via `shellout`, forwarding any CLI
///    arguments captured with `argv`. The original process does not run
///    `test_main` itself.
/// 2. Second pass (env var set): skip generation, unset the env var, and
///    invoke `test_main` directly so the freshly-generated tests run.
pub fn run_with(config: GleedocConfig, test_main: fn() -> Nil) -> Nil {
  let forwarded_args = argv.load().arguments
  run_with_inner(config, test_main, forwarded_args)
}

fn run_with_inner(
  config: GleedocConfig,
  test_main: fn() -> Nil,
  forwarded_args: List(String),
) -> Nil {
  case envoy.get(test_generation_running) {
    // Second pass: tests have been generated, just run them.
    Ok(_) -> {
      envoy.unset(test_generation_running)
      test_main()
    }

    // First pass: generate tests then re-invoke `gleam test`.
    Error(_) -> {
      case run(config) {
        Error(snag) -> panic as snag.issue
        Ok(Nil) -> {
          let result =
            shellout.command(
              run: "gleam",
              with: ["test", ..forwarded_args],
              in: ".",
              opt: [
                LetBeStdout,
                LetBeStderr,
                SetEnvironment([#(test_generation_running, "true")]),
              ],
            )
          case result {
            Ok(_) -> Nil
            Error(#(status, message)) -> {
              case message {
                "" -> Nil
                _ -> io.println(message)
              }
              shellout.exit(status)
            }
          }
        }
      }
    }
  }
}

fn find_gleam_files(source_dir: String) -> Result(List(String), snag.Snag) {
  find_gleam_files_loop(source_dir, [])
}

fn find_gleam_files_loop(
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
    let path = filepath.join(dir, entry)
    use is_dir <- result.try(
      path
      |> simplifile.is_directory
      |> result.map_error(fn(err) {
        snag.new("Failed to stat: " <> path <> " - " <> string.inspect(err))
      }),
    )

    case is_dir {
      True -> find_gleam_files_loop(path, acc)
      False -> {
        case string.ends_with(path, ".gleam") {
          True -> Ok([path, ..acc])
          False -> Ok(acc)
        }
      }
    }
  })
}
