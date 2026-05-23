//// Release preparation script.
////
//// Usage:
////   gleam run -m prepare_release -- <version>
////
//// Example:
////   gleam run -m prepare_release -- 0.6.0
////
//// Steps:
////   1. Update CHANGELOG.md via `git cliff --tag v<version> --unreleased --prepend CHANGELOG.md`.
////      The changelog format is configured in `cliff.toml` at the repo root.
////   2. Bump the `version` field in `gleam.toml`.
////   3. `git add CHANGELOG.md gleam.toml` and commit with message `build: bump version number`.
////   4. `git tag <version>`.

import argv
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import shellout.{LetBeStderr, LetBeStdout}
import simplifile

const gleam_toml_path = "gleam.toml"

const changelog_path = "CHANGELOG.md"

pub fn main() {
  case argv.load().arguments {
    [version] -> {
      case run(version) {
        Ok(Nil) -> {
          io.println("✅ Release " <> version <> " prepared successfully.")
          io.println(
            "   Don't forget to push the commit and the tag:\n"
            <> "     git push && git push origin v"
            <> version,
          )
        }
        Error(message) -> {
          io.println_error("❌ " <> message)
          shellout.exit(1)
        }
      }
    }
    _ -> {
      io.println_error(
        "Usage: gleam run -m prepare_release -- <version>\n"
        <> "Example: gleam run -m prepare_release -- 0.6.0",
      )
      shellout.exit(1)
    }
  }
}

fn run(version: String) -> Result(Nil, String) {
  use _ <- result.try(validate_version(version))
  let tag = "v" <> version

  io.println("→ Updating " <> changelog_path <> " with git-cliff...")
  use _ <- result.try(update_changelog(tag))

  io.println("→ Bumping version in " <> gleam_toml_path <> " to " <> version)
  use _ <- result.try(update_gleam_toml(version))

  io.println("→ Staging and committing changes...")
  use _ <- result.try(git_commit())

  io.println("→ Creating git tag " <> tag)
  use _ <- result.try(git_tag(tag))

  Ok(Nil)
}

/// Very loose semver-ish check: must be non-empty and start with a digit, so
/// that callers don't accidentally pass e.g. "v0.6.0" (which would result in a
/// tag of "vv0.6.0").
fn validate_version(version: String) -> Result(Nil, String) {
  let starts_with_digit =
    ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
    |> list.any(string.starts_with(version, _))

  case starts_with_digit {
    True -> Ok(Nil)
    False ->
      Error(
        "Invalid version \""
        <> version
        <> "\". Expected a version number like 0.6.0 (without the leading 'v').",
      )
  }
}

fn update_changelog(tag: String) -> Result(Nil, String) {
  shellout.command(
    run: "git",
    with: [
      "cliff",
      "--tag",
      tag,
      "--unreleased",
      "--prepend",
      changelog_path,
    ],
    in: ".",
    opt: [LetBeStdout, LetBeStderr],
  )
  |> result.replace(Nil)
  |> result.map_error(fn(err) {
    let #(_status, message) = err
    "git-cliff failed: " <> message
  })
}

fn update_gleam_toml(version: String) -> Result(Nil, String) {
  use contents <- result.try(
    simplifile.read(gleam_toml_path)
    |> result.map_error(fn(err) {
      "Failed to read "
      <> gleam_toml_path
      <> ": "
      <> simplifile.describe_error(err)
    }),
  )

  use new_contents <- result.try(replace_version_line(contents, version))

  simplifile.write(gleam_toml_path, new_contents)
  |> result.map_error(fn(err) {
    "Failed to write "
    <> gleam_toml_path
    <> ": "
    <> simplifile.describe_error(err)
  })
}

/// Replace the first line that starts with `version = ` with `version = "<v>"`.
/// Errors if no such line is found.
fn replace_version_line(
  contents: String,
  version: String,
) -> Result(String, String) {
  let lines = string.split(contents, "\n")
  let new_line = "version = \"" <> version <> "\""

  let #(found, updated_lines) =
    list.map_fold(lines, False, fn(found, line) {
      case found, string.starts_with(string.trim_start(line), "version = ") {
        False, True -> #(True, new_line)
        _, _ -> #(found, line)
      }
    })

  case found {
    True -> Ok(string.join(updated_lines, "\n"))
    False ->
      Error(
        "Could not find a `version = ...` line in " <> gleam_toml_path <> ".",
      )
  }
}

fn git_commit() -> Result(Nil, String) {
  use _ <- result.try(
    shellout.command(
      run: "git",
      with: ["add", changelog_path, gleam_toml_path],
      in: ".",
      opt: [LetBeStdout, LetBeStderr],
    )
    |> result.map_error(fn(err) {
      let #(_status, message) = err
      "git add failed: " <> message
    }),
  )

  shellout.command(
    run: "git",
    with: ["commit", "-m", "build: bump version number"],
    in: ".",
    opt: [LetBeStdout, LetBeStderr],
  )
  |> result.replace(Nil)
  |> result.map_error(fn(err) {
    let #(_status, message) = err
    "git commit failed: " <> message
  })
}

fn git_tag(tag: String) -> Result(Nil, String) {
  shellout.command(run: "git", with: ["tag", tag], in: ".", opt: [
    LetBeStdout,
    LetBeStderr,
  ])
  |> result.replace(Nil)
  |> result.map_error(fn(err) {
    let #(_status, message) = err
    "git tag failed: " <> message
  })
}
