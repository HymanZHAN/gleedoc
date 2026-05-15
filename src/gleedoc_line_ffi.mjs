export function separator() {
  return process.platform === "win32" ? "\r\n" : "\n";
}
