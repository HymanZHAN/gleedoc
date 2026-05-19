import gleam/option.{type Option}

/// Returns a greeting for the user.
///
/// ```gleam
/// import gleam/option.{Some}
///
/// let name = Some("Alice")
/// assert greet(name) == "Hello, Alice!"
/// 
/// let assert [greet, ..] = string.split(greet(name), ",")
/// assert greet == "Hello"
/// ```
pub fn greet(name: Option(String)) -> String {
  name
  |> option.map(fn(n) { "Hello, " <> n <> "!" })
  |> option.unwrap("")
}
