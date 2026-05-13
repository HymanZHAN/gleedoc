import gleam/option.{type Option}

/// Returns a greeting for the user.
///
/// ```gleam
/// import gleam/option.{Some}
///
/// let name = Some("Alice")
/// assert greet(name) == "Hello, Alice!"
/// ```
pub fn greet(name: Option(String)) -> String {
  name
  |> option.map(fn(n) { "Hello, " <> n <> "!" })
  |> option.unwrap("")
}
