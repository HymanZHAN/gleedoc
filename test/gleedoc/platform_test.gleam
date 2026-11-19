import gleedoc/internal/platform

pub fn erlang_flags_test() {
  assert platform.gleam_flags(platform.Erlang) == ["--target", "erlang"]
}

pub fn javascript_flags_test() {
  assert platform.gleam_flags(platform.JavaScript(runtime: "deno"))
    == ["--target", "javascript", "--runtime", "deno"]
}

pub fn current_matches_compile_target_test() {
  let expected = case target() {
    "erlang" -> platform.Erlang
    _ -> platform.JavaScript(runtime: "nodejs")
  }
  assert platform.current() == expected
}

@external(javascript, "../gleedoc_test_ffi.mjs", "target")
fn target() -> String {
  "erlang"
}
