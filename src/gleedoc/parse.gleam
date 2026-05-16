import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleedoc/extract.{type DocBlock}

/// Represents a fenced code block extracted from a doc comment.
pub type CodeBlock {
  CodeBlock(
    /// The language tag, e.g. "gleam" or ""
    language: String,
    /// The raw code inside the fence (without import statements)
    code: String,
    /// The source doc block this came from
    source: DocBlock,
    /// The 1-based line number within the doc comment where the code block starts
    doc_line_offset: Int,
    /// Import statements extracted from the code block
    imports: List(String),
  )
}

/// Extract all fenced code blocks from a list of doc blocks.
pub fn extract_gleam_blocks(doc_blocks: List(DocBlock)) -> List(CodeBlock) {
  doc_blocks
  |> list.flat_map(doc_block_to_code_block)
  |> list.filter(fn(b) { string.lowercase(b.language) == "gleam" })
}

fn doc_block_to_code_block(doc: DocBlock) -> List(CodeBlock) {
  let #(accumulated, current) =
    list.index_fold(doc.lines, #([], None), fn(state, line, line_no) {
      let #(accumulated, current) = state
      let trimmed = string.trim(line)
      case current, trimmed {
        None, "```" <> rest -> {
          let lang = string.trim(rest)
          #(accumulated, Some(#(lang, [], line_no + 1)))
        }
        None, _ -> state
        Some(#(lang, code_lines, start)), "```" -> {
          #([build_block(lang, code_lines, start, doc), ..accumulated], None)
        }
        Some(#(lang, code_lines, start)), _ -> {
          #(accumulated, Some(#(lang, [line, ..code_lines], start)))
        }
      }
    })

  let final_accumulated = case current {
    Some(#(lang, code_lines, start)) -> [
      build_block(lang, code_lines, start, doc),
      ..accumulated
    ]
    None -> accumulated
  }

  list.reverse(final_accumulated)
}

fn build_block(
  lang: String,
  code_lines: List(String),
  start: Int,
  doc: DocBlock,
) -> CodeBlock {
  let code = list.reverse(code_lines) |> string.join("\n")
  let #(imports, code) = extract_imports(code)
  CodeBlock(
    language: lang,
    code: code,
    source: doc,
    doc_line_offset: start,
    imports: imports,
  )
}

/// Extract import statements from code and return them separately.
fn extract_imports(code: String) -> #(List(String), String) {
  let #(imports, rest) =
    code
    |> string.split("\n")
    |> list.map(fn(line) { #(string.trim(line), line) })
    |> list.partition(fn(pair) { string.starts_with(pair.0, "import ") })

  #(
    imports |> list.map(fn(pair) { pair.0 }),
    rest |> list.map(fn(pair) { pair.1 }) |> string.join("\n"),
  )
}
