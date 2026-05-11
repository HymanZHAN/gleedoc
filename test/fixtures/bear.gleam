import gleam/order
import gleam/string

pub type Bear {
  Bear(id: Int, name: String, kind: String, hibernating: Bool)
}

/// Compares two bears by name in ascending alphabetical order.
///
/// Returns `order.Lt` if `a` comes before `b`, `order.Eq` if both names are
/// identical, and `order.Gt` if `a` comes after `b`. Suitable for use with
/// `list.sort`.
///
/// ## Examples
///
/// ```gleam
/// let alpha = Bear(id: 1, name: "Alpha", kind: "Grizzly", hibernating: False)
/// let beta  = Bear(id: 2, name: "Beta",  kind: "Polar",   hibernating: True)
/// assert order_asc_by_name(alpha, beta) == order.Lt
/// ```
///
/// ```gleam
///
/// let alpha = Bear(id: 1, name: "Zara", kind: "Grizzly", hibernating: False)
/// let beta  = Bear(id: 2, name: "Zara", kind: "Polar",   hibernating: True)
/// assert order_asc_by_name(alpha, beta) == order.Eq
/// ```
///
/// ```gleam
/// let alpha = Bear(id: 1, name: "Zara",  kind: "Grizzly", hibernating: False)
/// let beta  = Bear(id: 2, name: "Alpha", kind: "Polar",   hibernating: True)
/// assert order_asc_by_name(alpha, beta) == order.Gt
/// ```
///
pub fn order_asc_by_name(a: Bear, b: Bear) -> order.Order {
  string.compare(a.name, b.name)
}
