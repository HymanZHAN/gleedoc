import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import gleedoc/extract.{type DocBlock}

/// Represents a fenced code block extracted from a doc comment.
pub type CodeBlock {
  CodeBlock(
    /// The language tag, e.g. "gleam" or ""
    language: String,
    /// The raw code inside the fence
    code: String,
    /// The source doc block this came from
    source: DocBlock,
    /// The 1-based line number within the doc comment where the code block starts
    doc_line_offset: Int,
  )
}

/// Extract all fenced code blocks from a list of doc blocks.
pub fn extract_code_blocks(doc_blocks: List(DocBlock)) -> List(CodeBlock) {
  doc_blocks
  |> list.flat_map(fn(doc) {
    let lines = doc.lines
    extract_from_lines(lines, [], None, 1, doc)
  })
}

fn extract_from_lines(
  lines: List(String),
  accumulated: List(CodeBlock),
  current_block: Option(#(String, List(String), Int)),
  line_no: Int,
  doc: DocBlock,
) -> List(CodeBlock) {
  case lines {
    [] -> {
      case current_block {
        Some(#(lang, code_lines, start)) -> {
          let code = code_lines |> list.reverse |> string.join("\n")
          let block =
            CodeBlock(
              language: lang,
              code: code,
              source: doc,
              doc_line_offset: start,
            )
          list.reverse([block, ..accumulated])
        }
        None -> list.reverse(accumulated)
      }
    }

    [line, ..rest] -> {
      let trimmed = string.trim(line)
      case current_block {
        None -> {
          case string.starts_with(trimmed, "```") {
            True -> {
              let lang = string.drop_start(trimmed, 3) |> string.trim
              extract_from_lines(
                rest,
                accumulated,
                Some(#(lang, [], line_no)),
                line_no + 1,
                doc,
              )
            }
            False ->
              extract_from_lines(rest, accumulated, None, line_no + 1, doc)
          }
        }
        Some(#(lang, code_lines, start)) -> {
          case trimmed == "```" {
            True -> {
              let code = code_lines |> list.reverse |> string.join("\n")
              let block =
                CodeBlock(
                  language: lang,
                  code: code,
                  source: doc,
                  doc_line_offset: start,
                )
              extract_from_lines(
                rest,
                [block, ..accumulated],
                None,
                line_no + 1,
                doc,
              )
            }
            False -> {
              extract_from_lines(
                rest,
                accumulated,
                Some(#(lang, [line, ..code_lines], start)),
                line_no + 1,
                doc,
              )
            }
          }
        }
      }
    }
  }
}

/// Filter code blocks to only those tagged as `gleam`.
pub fn gleam_blocks(blocks: List(CodeBlock)) -> List(CodeBlock) {
  list.filter(blocks, fn(b) { string.lowercase(b.language) == "gleam" })
}

/// Group code blocks by their target definition.
pub fn group_by_target(
  blocks: List(CodeBlock),
) -> List(#(Option(String), List(CodeBlock))) {
  blocks
  |> list.fold([], fn(groups, block) {
    let target = block.source.target
    case list_find(groups, fn(pair) { pair.0 == target }) {
      Ok(#(_, existing)) -> {
        list.map(groups, fn(pair) {
          case pair.0 == target {
            True -> #(target, [block, ..existing])
            False -> pair
          }
        })
      }
      Error(Nil) -> [#(target, [block]), ..groups]
    }
  })
  |> list.map(fn(pair) { #(pair.0, list.reverse(pair.1)) })
}

fn list_find(
  list: List(#(a, b)),
  predicate: fn(#(a, b)) -> Bool,
) -> Result(#(a, b), Nil) {
  case list {
    [] -> Error(Nil)
    [x, ..rest] ->
      case predicate(x) {
        True -> Ok(x)
        False -> list_find(rest, predicate)
      }
  }
}
