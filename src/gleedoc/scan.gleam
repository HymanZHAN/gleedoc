import glance
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import snag

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Scan a Gleam source file and extract all public definition names.
pub fn public_names(
  file_path: String,
  source: String,
) -> Result(List(String), snag.Snag) {
  use module <- result.try(parse_module(file_path, source))

  let pub_functions =
    module.functions
    |> list.filter_map(fn(d) {
      if_public(d.definition.publicity, d.definition.name)
    })

  let pub_types =
    list.filter_map(module.custom_types, fn(d) {
      if_public(d.definition.publicity, d.definition.name)
    })

  let pub_constants =
    list.filter_map(module.constants, fn(d) {
      if_public(d.definition.publicity, d.definition.name)
    })

  let pub_names = list.flatten([pub_functions, pub_types, pub_constants])

  Ok(pub_names)
}

/// Scan a Gleam source file and return its top-level import statements
/// reconstructed as import strings (e.g. `"import gleam/order"`).
pub fn module_imports(
  file_path: String,
  source: String,
) -> Result(List(String), snag.Snag) {
  use module <- result.try(parse_module(file_path, source))

  let imports =
    module.imports
    |> list.map(fn(def) {
      let imp = def.definition
      let base = "import " <> imp.module
      let unqualified =
        list.flatten([
          imp.unqualified_types |> list.map(format_unqualified),
          imp.unqualified_values |> list.map(format_unqualified),
        ])
      case unqualified {
        [] -> base
        names -> base <> ".{" <> string.join(names, ", ") <> "}"
      }
    })

  Ok(imports)
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn parse_module(
  file_path: String,
  source: String,
) -> Result(glance.Module, snag.Snag) {
  source
  |> glance.module
  |> result.map_error(fn(err) {
    snag.new("Failed to parse " <> file_path <> ": " <> string.inspect(err))
  })
}

fn if_public(publicity: glance.Publicity, name: String) -> Result(String, Nil) {
  case publicity {
    glance.Public -> Ok(name)
    _ -> Error(Nil)
  }
}

fn format_unqualified(u: glance.UnqualifiedImport) -> String {
  case u.alias {
    Some(a) -> u.name <> " as " <> a
    None -> u.name
  }
}
