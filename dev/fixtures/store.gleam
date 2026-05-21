//// A simple key-value store backed by a dictionary.
////
//// ## Examples
////
//// ```gleam
//// let s = store.new() |> store.insert("name", "Gleam")
////
//// assert s |> store.get("name") == option.Some("Gleam")
//// assert s |> store.get("age") == option.None
//// ```
////
//// ```gleam
//// let s = store.new() |> store.insert("count", 5)
////
//// assert s |> store.get("count") |> option.unwrap(0) == 5
////
//// // `gleam/int` is not imported anywhere in this file, so it has to be
//// // resolved by `extra_imports`.
//// assert s |> get("nothing") |> option.map(fn(_){20}) |> option.unwrap(42) |> int.to_string == "42"
//// ```
////

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

/// `gleam/int` is not imported anywhere in this file, so it has to be resolved
/// by extra_imports.
///
/// ```gleam
/// let s = new() |> insert("x", 42)
///
/// assert get(s, "x") == Some(42)
/// assert get(s, "y") == None
/// ```
/// 
/// The following example contains failing tests, but because it's ignored,
/// the test suite will still pass.
/// 
/// ```gleam,ignore
/// let s = new() |> insert("x", 42)
///
/// assert get(s, "x") == Some(53)
/// assert get(s, "y") == Some(42)
/// ```
pub fn get(store: Store(v), key: String) -> Option(v) {
  case dict.get(store.data, key) {
    Ok(v) -> Some(v)
    Error(_) -> None
  }
}
