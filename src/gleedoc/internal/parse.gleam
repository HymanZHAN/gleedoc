import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleedoc/internal/extract.{type DocBlock}

/// Represents a fenced code block extracted from a doc comment.
pub type CodeBlock {
  CodeBlock(
    /// The language tag, e.g. "gleam" or ""
    language: String,
    /// Attributes following the language tag, e.g. `["ignore"]` for
    /// ` ```gleam,ignore `. Always lowercased and trimmed.
    attributes: List(String),
    /// The raw code inside the fence (without import statements)
    code: String,
    /// The 1-based line number within the doc comment for each line of `code`,
    /// in the same order. Used to map code lines back to source file lines.
    code_line_offsets: List(Int),
    /// The source doc block this came from
    source: DocBlock,
    /// The 1-based line number within the doc comment where the code block starts
    doc_line_offset: Int,
    /// Import statements extracted from the code block
    imports: List(String),
  )
}

/// Extract all fenced code blocks from a list of doc blocks.
///
/// Only blocks tagged with `gleam` are kept, and any block with the `ignore`
/// attribute (e.g. ` ```gleam,ignore `) is skipped.
pub fn extract_gleam_blocks(doc_blocks: List(DocBlock)) -> List(CodeBlock) {
  doc_blocks
  |> list.flat_map(doc_block_to_code_blocks)
  |> list.filter(fn(b) { b.language == "gleam" })
  |> list.filter(fn(b) { !list.contains(b.attributes, "ignore") })
}

fn doc_block_to_code_blocks(doc: DocBlock) -> List(CodeBlock) {
  let #(accumulated, current) =
    doc.lines
    |> list.index_fold(#([], None), fn(state, line, line_no) {
      let #(accumulated, current) = state
      let trimmed = string.trim(line)
      // `line_no` is 0-based; doc-line offsets are 1-based.
      let offset = line_no + 1
      case current, trimmed {
        None, "```" <> rest -> {
          let lang = string.trim(rest)
          #(accumulated, Some(#(lang, [], offset)))
        }
        None, _ -> state
        Some(#(lang, code_lines, start)), "```" -> {
          let code_lines = code_lines |> list.reverse
          #([build_block(lang, code_lines, start, doc), ..accumulated], None)
        }
        Some(#(lang, code_lines, start)), _ -> {
          #(accumulated, Some(#(lang, [#(offset, line), ..code_lines], start)))
        }
      }
    })

  let final_accumulated = case current {
    Some(#(lang, code_lines, start)) -> [
      build_block(lang, code_lines |> list.reverse, start, doc),
      ..accumulated
    ]
    None -> accumulated
  }

  list.reverse(final_accumulated)
}

fn build_block(
  info_string: String,
  code_lines: List(#(Int, String)),
  start: Int,
  doc: DocBlock,
) -> CodeBlock {
  let #(imports, kept) = extract_imports(code_lines)
  let code = kept |> list.map(fn(pair) { pair.1 }) |> string.join("\n")
  let code_line_offsets = kept |> list.map(fn(pair) { pair.0 })
  let #(language, attributes) = parse_info_string(info_string)

  CodeBlock(
    language: language,
    attributes: attributes,
    code: code,
    code_line_offsets: code_line_offsets,
    source: doc,
    doc_line_offset: start,
    imports: imports,
  )
}

/// Parse a fenced code block info string like `gleam,ignore` into a
/// `#(language, attributes)` pair, e.g. `#("gleam", ["ignore"])`.
fn parse_info_string(info_string: String) -> #(String, List(String)) {
  case info_string |> string.lowercase |> string.split(",") {
    [lang, ..attrs] -> #(lang, attrs)
    [] -> #("", [])
  }
}

/// Extract import statements from a list of `#(doc_line_offset, line)` pairs,
/// returning the trimmed import statements and the remaining lines (with
/// their offsets preserved).
fn extract_imports(
  lines: List(#(Int, String)),
) -> #(List(String), List(#(Int, String))) {
  let #(imports, rest) =
    lines
    |> list.partition(fn(pair) {
      pair.1 |> string.trim |> string.starts_with("import ")
    })

  #(imports |> list.map(fn(pair) { string.trim(pair.1) }), rest)
}
