import glance
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import snag

/// Scan a Gleam source file and extract all public definition names.
pub fn public_names(
  file_path: String,
  source: String,
) -> Result(List(String), snag.Snag) {
  use module <- result.try(
    source
    |> glance.module
    |> result.map_error(fn(err) {
      snag.new("Failed to parse " <> file_path <> ": " <> string.inspect(err))
    }),
  )

  let functions =
    module.functions
    |> list.filter_map(fn(def) {
      case def.definition.publicity {
        glance.Public -> Ok(def.definition.name)
        _ -> Error(Nil)
      }
    })

  let types =
    module.custom_types
    |> list.filter_map(fn(def) {
      case def.definition.publicity {
        glance.Public -> Ok(def.definition.name)
        _ -> Error(Nil)
      }
    })

  let constants =
    module.constants
    |> list.filter_map(fn(def) {
      case def.definition.publicity {
        glance.Public -> Ok(def.definition.name)
        _ -> Error(Nil)
      }
    })

  Ok(list.flatten([functions, types, constants]))
}

/// Scan a Gleam source file and return its top-level import statements
/// reconstructed as import strings (e.g. `"import gleam/order"`).
pub fn module_imports(
  file_path: String,
  source: String,
) -> Result(List(String), snag.Snag) {
  use module <- result.try(
    source
    |> glance.module
    |> result.map_error(fn(err) {
      snag.new("Failed to parse " <> file_path <> ": " <> string.inspect(err))
    }),
  )

  let imports =
    module.imports
    |> list.map(fn(def) {
      let imp = def.definition
      let base = "import " <> imp.module
      let unqualified =
        list.append(
          imp.unqualified_types
            |> list.map(fn(u) {
              case u.alias {
                Some(a) -> u.name <> " as " <> a
                None -> u.name
              }
            }),
          imp.unqualified_values
            |> list.map(fn(u) {
              case u.alias {
                Some(a) -> u.name <> " as " <> a
                None -> u.name
              }
            }),
        )
      case unqualified {
        [] -> base
        names -> base <> ".{" <> string.join(names, ", ") <> "}"
      }
    })

  Ok(imports)
}
