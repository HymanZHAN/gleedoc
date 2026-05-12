import gleam/list
import gleedoc/scan
import simplifile

const bear_fixture = "test/fixtures/bear.gleam"

const store_fixture = "test/fixtures/store.gleam"

// ---------------------------------------------------------------------------
// public_names
// ---------------------------------------------------------------------------

pub fn scan_public_names_functions_test() {
  let assert Ok(names) = scan.public_names(bear_fixture, read(bear_fixture))
  assert list.contains(names, "order_asc_by_name")
}

pub fn scan_public_names_types_test() {
  let assert Ok(names) = scan.public_names(bear_fixture, read(bear_fixture))
  assert list.contains(names, "Bear")
}

pub fn scan_public_names_no_private_test() {
  let assert Ok(names) = scan.public_names(store_fixture, read(store_fixture))
  // All of new, insert, get, Store are public — nothing private to leak, but
  // the count must exactly match the three pub fns + one pub type.
  assert list.length(names) == 4
}

// ---------------------------------------------------------------------------
// module_imports — plain imports (no unqualified names)
// ---------------------------------------------------------------------------

pub fn scan_module_imports_plain_test() {
  let assert Ok(imports) = scan.module_imports(bear_fixture, read(bear_fixture))
  assert list.contains(imports, "import gleam/order")
  assert list.contains(imports, "import gleam/string")
}

// ---------------------------------------------------------------------------
// module_imports — unqualified value imports
// ---------------------------------------------------------------------------

pub fn scan_module_imports_unqualified_value_test() {
  // gleam/option is imported as: import gleam/option.{type Option, None, Some}
  // None and Some are values and must NOT be prefixed with `type `.
  let assert Ok(imports) =
    scan.module_imports(store_fixture, read(store_fixture))
  let assert Ok(option_import) =
    list.find(imports, fn(i) {
      i == "import gleam/option.{type Option, None, Some}"
    })
  assert option_import == "import gleam/option.{type Option, None, Some}"
}

// ---------------------------------------------------------------------------
// module_imports — unqualified type imports must carry `type ` prefix
// ---------------------------------------------------------------------------

pub fn scan_module_imports_unqualified_type_prefix_test() {
  // gleam/dict is imported as: import gleam/dict.{type Dict}
  // Dict is a type and must be rendered as `type Dict`, not plain `Dict`.
  let assert Ok(imports) =
    scan.module_imports(store_fixture, read(store_fixture))
  let assert Ok(dict_import) =
    list.find(imports, fn(i) {
      i == "import gleam/dict.{type Dict}" || i == "import gleam/dict.{Dict}"
    })
  assert dict_import == "import gleam/dict.{type Dict}"
}

pub fn scan_module_imports_unqualified_type_no_bare_name_test() {
  // Ensure the bare (incorrect) form `import gleam/dict.{Dict}` is never produced.
  let assert Ok(imports) =
    scan.module_imports(store_fixture, read(store_fixture))
  assert !list.contains(imports, "import gleam/dict.{Dict}")
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn read(path: String) -> String {
  let assert Ok(src) = simplifile.read(path)
  src
}
