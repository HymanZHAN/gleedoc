import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile
import snag

/// Represents an extracted doc comment block from a Gleam source file.
pub type DocBlock {
  DocBlock(
    /// The doc comment lines with the `///` prefix stripped and whitespace trimmed.
    lines: List(String),
    /// The name of the definition this doc comment precedes, if any.
    target: Option(String),
    /// The file path the doc block was extracted from.
    file: String,
    /// The 1-based line number where the doc block starts.
    start_line: Int,
  )
}

/// Extract all doc comment blocks from a Gleam source file.
pub fn doc_blocks_from_file(
  file_path: String,
) -> Result(List(DocBlock), snag.Snag) {
  use content <- result.try(
    simplifile.read(file_path)
    |> result.map_error(fn(err) {
      snag.new(
        "Failed to read file: " <> file_path <> " - " <> string.inspect(err),
      )
    }),
  )

  let lines =
    content
    |> string.split("\n")
    |> list.index_map(fn(line, index) { #(index + 1, line) })

  Ok(extract_blocks(lines, [], [], file_path))
}

fn extract_blocks(
  lines: List(#(Int, String)),
  accumulated: List(DocBlock),
  current_doc: List(#(Int, String)),
  file: String,
) -> List(DocBlock) {
  case lines {
    [] -> {
      // End of file - if there's a pending doc block with no target, we could
      // include it as module-level docs. For now we drop trailing docs without targets.
      case current_doc {
        [] -> list.reverse(accumulated)
        _ -> list.reverse(accumulated)
      }
    }

    [#(line_no, line), ..rest] -> {
      let trimmed = string.trim_start(line)
      case string.starts_with(trimmed, "///") {
        True -> {
          let doc_line = trimmed |> string.drop_start(3) |> string.trim_start
          extract_blocks(
            rest,
            accumulated,
            [#(line_no, doc_line), ..current_doc],
            file,
          )
        }
        False -> {
          case current_doc {
            [] -> extract_blocks(rest, accumulated, [], file)
            _ -> {
              let is_blank = string.trim(line) == ""
              case is_blank {
                True -> extract_blocks(rest, accumulated, current_doc, file)
                False -> {
                  let target = extract_definition_name(line)
                  let start_line =
                    current_doc
                    |> list.last
                    |> fn(x) {
                      case x {
                        Ok(#(ln, _)) -> ln
                        Error(Nil) -> line_no
                      }
                    }
                  let doc_lines =
                    current_doc
                    |> list.reverse
                    |> list.map(fn(pair) { pair.1 })
                  let block =
                    DocBlock(
                      lines: doc_lines,
                      target: target,
                      file: file,
                      start_line: start_line,
                    )
                  extract_blocks(rest, [block, ..accumulated], [], file)
                }
              }
            }
          }
        }
      }
    }
  }
}

/// Try to extract a definition name from a source line.
fn extract_definition_name(line: String) -> Option(String) {
  let trimmed = string.trim_start(line)

  // Try to match: pub fn name( or fn name(
  case try_extract_function_name(trimmed) {
    Ok(name) -> Some(name)
    Error(Nil) -> {
      // Try to match: pub type Name or type Name
      case try_extract_type_name(trimmed) {
        Ok(name) -> Some(name)
        Error(Nil) -> {
          // Try to match: pub const name or const name
          case try_extract_const_name(trimmed) {
            Ok(name) -> Some(name)
            Error(Nil) -> None
          }
        }
      }
    }
  }
}

fn try_extract_function_name(line: String) -> Result(String, Nil) {
  let line = case string.starts_with(line, "pub ") {
    True -> string.drop_start(line, 4)
    False -> line
  }
  case string.starts_with(line, "fn ") {
    True -> {
      let rest = string.drop_start(line, 3) |> string.trim_start
      case string.split_once(rest, "(") {
        Ok(#(name, _)) -> Ok(string.trim(name))
        Error(Nil) -> Error(Nil)
      }
    }
    False -> Error(Nil)
  }
}

fn try_extract_type_name(line: String) -> Result(String, Nil) {
  let line = case string.starts_with(line, "pub ") {
    True -> string.drop_start(line, 4)
    False -> line
  }
  case string.starts_with(line, "type ") {
    True -> {
      let rest = string.drop_start(line, 5) |> string.trim_start
      // Handle opaque types: pub opaque type Name
      let rest = case string.starts_with(rest, "opaque ") {
        True -> string.drop_start(rest, 7) |> string.trim_start
        False -> rest
      }
      case string.split_once(rest, " ") {
        Ok(#(name, _)) -> Ok(string.trim(name))
        Error(Nil) -> {
          case string.split_once(rest, "{") {
            Ok(#(name, _)) -> Ok(string.trim(name))
            Error(Nil) -> Ok(string.trim(rest))
          }
        }
      }
    }
    False -> Error(Nil)
  }
}

fn try_extract_const_name(line: String) -> Result(String, Nil) {
  let line = case string.starts_with(line, "pub ") {
    True -> string.drop_start(line, 4)
    False -> line
  }
  case string.starts_with(line, "const ") {
    True -> {
      let rest = string.drop_start(line, 6) |> string.trim_start
      case string.split_once(rest, " ") {
        Ok(#(name, _)) -> Ok(string.trim(name))
        Error(Nil) -> Ok(string.trim(rest))
      }
    }
    False -> Error(Nil)
  }
}
