/// The platform the current program is running on.
///
/// `gleam test` consumes the `--target` and `--runtime` flags itself and
/// does not forward them to the test program, so when `gleedoc` re-invokes
/// `gleam test` it has to work out which platform it is on and pass those
/// flags along explicitly. Otherwise the second pass silently runs on the
/// project's default target.
pub type Platform {
  Erlang
  /// `runtime` is one of `"nodejs"`, `"deno"` or `"bun"`.
  JavaScript(runtime: String)
}

/// Detect the platform the current program is running on.
pub fn current() -> Platform {
  case javascript_runtime() {
    "" -> Erlang
    runtime -> JavaScript(runtime:)
  }
}

/// The `gleam test` flags that select the given platform.
pub fn gleam_flags(platform: Platform) -> List(String) {
  case platform {
    Erlang -> ["--target", "erlang"]
    JavaScript(runtime:) -> ["--target", "javascript", "--runtime", runtime]
  }
}

/// The name of the JavaScript runtime, or `""` when running on Erlang.
@external(javascript, "../../gleedoc_ffi.mjs", "runtime")
fn javascript_runtime() -> String {
  ""
}
