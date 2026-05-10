/// A simple example module demonstrating gleedoc.
///
/// ```gleam
/// let result = add(1, 2)
/// let assert True = result == 3
/// ```
pub fn add(a: Int, b: Int) -> Int {
  a + b
}

/// Multiply two numbers.
///
/// ```gleam
/// let result = multiply(3, 4)
/// let assert True = result == 12
/// ```
pub fn multiply(a: Int, b: Int) -> Int {
  a * b
}

/// Greet a user by name.
///
/// ```gleam
/// let msg = greet("Alice")
/// let assert True = msg == "Hello, Alice!"
/// ```
pub fn greet(name: String) -> String {
  "Hello, " <> name <> "!"
}
