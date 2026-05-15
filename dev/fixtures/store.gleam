import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}

/// A simple key-value store backed by a Dict.
pub type Store(v) {
  Store(data: Dict(String, v))
}

/// Create an empty store.
pub fn new() -> Store(v) {
  Store(data: dict.new())
}

/// Insert a value into the store.
pub fn insert(store: Store(v), key: String, value: v) -> Store(v) {
  Store(data: dict.insert(store.data, key, value))
}

/// Look up a value in the store.
///
/// ```gleam
/// let s = new() |> insert("x", 42)
///
/// assert get(s, "x") == Some(42)
/// assert get(s, "y") == None
/// ```
pub fn get(store: Store(v), key: String) -> Option(v) {
  case dict.get(store.data, key) {
    Ok(v) -> Some(v)
    Error(_) -> None
  }
}
