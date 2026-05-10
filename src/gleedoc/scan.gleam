import glance
import gleam/list
import gleam/result
import gleam/string
import snag

/// Scan a Gleam source file and extract all public definition names.
pub fn public_names(
  file_path: String,
  source: String,
) -> Result(List(String), snag.Snag) {
  use module <- result.try(
    glance.module(source)
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
