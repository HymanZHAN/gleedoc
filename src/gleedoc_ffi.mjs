export function runtime() {
  if (globalThis.Deno) return "deno";
  if (globalThis.Bun) return "bun";
  return "nodejs";
}
