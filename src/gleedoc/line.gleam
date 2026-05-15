/// Returns the OS-native line separator: `"\r\n"` on Windows, `"\n"` everywhere else.
@external(erlang, "gleedoc_line_ffi", "separator")
@external(javascript, "../gleedoc_line_ffi.mjs", "separator")
pub fn separator() -> String
