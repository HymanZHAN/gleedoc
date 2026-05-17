import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleedoc/scan
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
    /// Public names exported by the source file (functions, types, constants).
    public_names: List(String),
    /// Top-level imports of the source file, formatted as import strings.
    module_imports: List(String),
  )
}

/// Extract all doc comment blocks from a Gleam source file.
pub fn doc_blocks_from_file(
  file_path: String,
) -> Result(List(DocBlock), snag.Snag) {
  use content <- result.try(
    file_path
    |> simplifile.read
    |> result.map_error(fn(err) {
      snag.new(
        "Failed to read file: " <> file_path <> " - " <> string.inspect(err),
      )
    }),
  )

  let public_names =
    scan.public_names(file_path, content)
    |> result.unwrap([])

  let module_imports =
    scan.module_imports(file_path, content)
    |> result.unwrap([])

  let doc_blocks =
    content
    |> string.replace("\r\n", "\n")
    |> string.split("\n")
    |> list.index_map(fn(line, index) { #(index + 1, line) })
    |> extract_blocks(file_path, public_names, module_imports)

  Ok(doc_blocks)
}

fn extract_blocks(
  lines: List(#(Int, String)),
  file: String,
  public_names: List(String),
  module_imports: List(String),
) -> List(DocBlock) {
  let #(processed_doc_blocks, _trailing_doc) =
    lines
    |> list.fold(#([], []), fn(state, item) {
      let #(processed_docs, current_doc) = state
      let #(line_no, line) = item
      let trimmed = string.trim_start(line)

      case string.starts_with(trimmed, "///") {
        // Still inside a doc comment — append this line to the buffer.
        True -> {
          let doc_line = trimmed |> string.drop_start(3)
          // There is normally a space between `///` and the actual code, and we
          // need to remove this space if it exists so that we don't need to
          // trim the whole doc_line and can preserve the original indentation.
          let doc_line = case doc_line |> string.starts_with(" ") {
            True -> doc_line |> string.drop_start(1)
            False -> doc_line
          }
          #(processed_docs, [#(line_no, doc_line), ..current_doc])
        }

        False -> {
          case current_doc {
            // No doc comment in progress — skip this line.
            [] -> state

            // Doc comment in progress.
            _ -> {
              case string.trim(line) == "" {
                // Blank line inside a doc block — keep buffering.
                True -> state

                // Non-blank, non-doc line after a doc block — finalize the block.
                False -> {
                  let target = extract_definition_name(line)

                  let start_line_number =
                    current_doc
                    |> list.last
                    |> result.map(fn(pair) { pair.0 })
                    |> result.unwrap(line_no)

                  let doc_lines =
                    current_doc
                    |> list.reverse
                    |> list.map(fn(pair) { pair.1 })

                  let new_doc =
                    DocBlock(
                      lines: doc_lines,
                      target: target,
                      file: file,
                      start_line: start_line_number,
                      public_names: public_names,
                      module_imports: module_imports,
                    )
                  #([new_doc, ..processed_docs], [])
                }
              }
            }
          }
        }
      }
    })

  // End of file — trailing docs without a target are dropped (same as before).
  list.reverse(processed_doc_blocks)
}

/// Try to extract a definition name from a source line.
fn extract_definition_name(line: String) -> Option(String) {
  let trimmed = string.trim_start(line)

  // Try each kind in turn; result.or moves to the next on failure.
  try_extract_function_name(trimmed)
  |> result.or(try_extract_type_name(trimmed))
  |> result.or(try_extract_const_name(trimmed))
  |> option.from_result
}

fn try_extract_function_name(line: String) -> Result(String, Nil) {
  // Strip optional "pub " prefix, then require "fn ".
  let line =
    string.split_once(line, "pub ")
    |> result.map(fn(pair) { pair.1 })
    |> result.unwrap(line)

  use rest <- result.try(string.split_once(line, "fn "))

  rest.1
  |> string.trim_start
  |> string.split_once("(")
  |> result.map(fn(pair) { string.trim(pair.0) })
}

fn try_extract_type_name(line: String) -> Result(String, Nil) {
  // Strip optional "pub " prefix, then require "type ".
  let line =
    string.split_once(line, "pub ")
    |> result.map(fn(pair) { pair.1 })
    |> result.unwrap(line)

  use rest <- result.try(string.split_once(line, "type "))

  // Handle opaque types: "opaque type Name" — strip the extra keyword if present.
  let rest =
    string.split_once(rest.1 |> string.trim_start, "opaque ")
    |> result.map(fn(pair) { pair.1 |> string.trim_start })
    |> result.unwrap(rest.1 |> string.trim_start)

  // The name ends at the first space, "{", or end-of-string.
  string.split_once(rest, " ")
  |> result.or(string.split_once(rest, "{"))
  |> result.map(fn(pair) { string.trim(pair.0) })
  |> result.unwrap(string.trim(rest))
  |> Ok
}

fn try_extract_const_name(line: String) -> Result(String, Nil) {
  // Strip optional "pub " prefix, then require "const ".
  let line =
    string.split_once(line, "pub ")
    |> result.map(fn(pair) { pair.1 })
    |> result.unwrap(line)

  use rest <- result.try(string.split_once(line, "const "))

  // The name ends at the first space, or end-of-string.
  string.split_once(rest.1 |> string.trim_start, " ")
  |> result.map(fn(pair) { string.trim(pair.0) })
  |> result.unwrap(string.trim(rest.1))
  |> Ok
}
