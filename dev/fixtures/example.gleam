import gleam/dict
import gleam/result

/// A simple example module demonstrating gleedoc.
///
/// ```gleam
/// let result = add(1, 2)
/// assert result == 3
/// ```
pub fn add(a: Int, b: Int) -> Int {
  a + b
}

/// Multiply two numbers.
///
/// ```gleam
/// let result = multiply(3, 4)
/// assert result == 12
/// ```
pub fn multiply(a: Int, b: Int) -> Int {
  a * b
}

/// Greet a user by name.
///
/// ```gleam
/// let msg = greet("Alice")
/// assert msg == "Hello, Alice!"
/// ```
pub fn greet(name: String) -> String {
  "Hello, " <> name <> "!"
}

pub type User {
  User(first_name: String, last_name: String)
}

/// Find a user by user ID.
///
/// ```gleam
/// let john = User("John", "Doe")
/// let bill = User("Bill", "Wilson")
///
/// let users =
///   [#("bill_wilson", bill), #("john_doe", john)]
///   |> dict.from_list
///
/// assert users |> find("hello") == User("", "")
/// assert users |> find("john_doe") == john
/// ```
pub fn find(data: dict.Dict(String, User), name: String) {
  let default_user = User("", "")
  data |> dict.get(name) |> result.unwrap(default_user)
}
