import glance
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import snag

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Scan a Gleam source file and extract all public definition names.
pub fn public_names(
  file_path: String,
  source: String,
) -> Result(List(String), snag.Snag) {
  use module <- result.try(parse_module(file_path, source))

  let pub_functions =
    module.functions
    |> list.filter_map(fn(d) {
      if_public(d.definition.publicity, d.definition.name)
    })

  let pub_types =
    list.filter_map(module.custom_types, fn(d) {
      if_public(d.definition.publicity, d.definition.name)
    })

  let pub_constants =
    list.filter_map(module.constants, fn(d) {
      if_public(d.definition.publicity, d.definition.name)
    })

  let pub_names = list.flatten([pub_functions, pub_types, pub_constants])

  Ok(pub_names)
}

/// Scan a Gleam source file and return its top-level import statements
/// reconstructed as import strings (e.g. `"import gleam/order"`).
pub fn module_imports(
  file_path: String,
  source: String,
) -> Result(List(String), snag.Snag) {
  use module <- result.try(parse_module(file_path, source))

  let imports =
    module.imports
    |> list.map(fn(def) {
      let imp = def.definition
      let base = "import " <> imp.module
      let unqualified =
        list.flatten([
          imp.unqualified_types
            |> list.map(fn(u) { format_unqualified(u, True) }),
          imp.unqualified_values
            |> list.map(fn(u) { format_unqualified(u, False) }),
        ])
      case unqualified {
        [] -> base
        names -> base <> ".{" <> string.join(names, ", ") <> "}"
      }
    })

  Ok(imports)
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

fn parse_module(
  file_path: String,
  source: String,
) -> Result(glance.Module, snag.Snag) {
  source
  |> glance.module
  |> result.map_error(fn(err) {
    snag.new("Failed to parse " <> file_path <> ": " <> string.inspect(err))
  })
}

fn if_public(publicity: glance.Publicity, name: String) -> Result(String, Nil) {
  case publicity {
    glance.Public -> Ok(name)
    _ -> Error(Nil)
  }
}

/// Analyse a generated test source and remove any import statements whose
/// module or unqualified names are never actually referenced in the code.
/// Returns the cleaned source text, or the original if parsing fails.
pub fn filter_unused_imports(source: String) -> String {
  case glance.module(source) {
    Error(_) -> source
    Ok(parsed) -> {
      let refs = collect_refs(parsed)
      let kept_imports =
        parsed.imports
        |> list.map(fn(def) { def.definition })
        |> list.filter(is_import_used(_, refs))
        |> list.map(construct_import(_, refs))
      // Reconstruct: header comment + imports + rest of body
      rebuild_source(source, kept_imports)
    }
  }
}

fn construct_import(imp: glance.Import, refs: Refs) -> String {
  let base = "import " <> imp.module
  let unqualified =
    list.flatten([
      imp.unqualified_types
        |> list.filter(is_unqualified_used(_, refs))
        |> list.map(format_unqualified(_, True)),
      imp.unqualified_values
        |> list.filter(is_unqualified_used(_, refs))
        |> list.map(format_unqualified(_, False)),
    ])
  case unqualified {
    [] -> base
    names -> base <> ".{" <> string.join(names, ", ") <> "}"
  }
}

// ---------------------------------------------------------------------------
// Ref-collection helpers
// ---------------------------------------------------------------------------

type Refs {
  Refs(
    /// Module aliases used as `alias.Something` (the alias part, e.g. "order")
    qualified: Set(String),
    /// Bare names used unqualified (constructors, functions, type names)
    unqualified: Set(String),
  )
}

fn empty_refs() -> Refs {
  Refs(qualified: set.new(), unqualified: set.new())
}

/// Walk every function body in the module and collect all name references.
fn collect_refs(module: glance.Module) -> Refs {
  module.functions
  |> list.fold(empty_refs(), fn(refs, def) {
    def.definition.body
    |> list.fold(refs, collect_refs_stmt)
  })
}

fn collect_refs_stmt(refs: Refs, stmt: glance.Statement) -> Refs {
  case stmt {
    glance.Expression(expr) -> collect_refs_expr(refs, expr)
    glance.Assignment(value: expr, ..) -> collect_refs_expr(refs, expr)
    glance.Assert(expression: expr, ..) -> collect_refs_expr(refs, expr)
    glance.Use(function: expr, ..) -> collect_refs_expr(refs, expr)
  }
}

fn collect_refs_expr(refs: Refs, expr: glance.Expression) -> Refs {
  case expr {
    // `module.name` — the container is a Variable holding the module alias
    glance.FieldAccess(container: glance.Variable(name: alias, ..), ..) ->
      Refs(..refs, qualified: refs.qualified |> set.insert(alias))

    glance.FieldAccess(container: inner, ..) -> collect_refs_expr(refs, inner)

    glance.Variable(name: name, ..) ->
      Refs(..refs, unqualified: refs.unqualified |> set.insert(name))

    glance.Call(function: f, arguments: args, ..) -> {
      let refs = refs |> collect_refs_expr(f)
      use r, field <- list.fold(args, refs)
      collect_refs_field_expr(r, field)
    }

    glance.BinaryOperator(left: l, right: r, ..) -> {
      let refs = collect_refs_expr(refs, l)
      collect_refs_expr(refs, r)
    }

    glance.Block(statements: stmts, ..) ->
      stmts |> list.fold(refs, collect_refs_stmt)

    glance.List(elements: elems, rest: rest, ..) -> {
      let refs = list.fold(elems, refs, collect_refs_expr)
      case rest {
        None -> refs
        Some(r) -> collect_refs_expr(refs, r)
      }
    }

    glance.Tuple(elements: elems, ..) ->
      list.fold(elems, refs, collect_refs_expr)

    glance.Fn(body: stmts, ..) -> list.fold(stmts, refs, collect_refs_stmt)

    glance.Case(subjects: subj, clauses: clauses, ..) -> {
      let refs = list.fold(subj, refs, collect_refs_expr)
      list.fold(clauses, refs, fn(r, clause) {
        let r = collect_refs_expr(r, clause.body)
        list.fold(clause.patterns, r, fn(r2, pats) {
          list.fold(pats, r2, collect_refs_pattern)
        })
      })
    }

    glance.NegateInt(value: inner, ..) -> collect_refs_expr(refs, inner)
    glance.NegateBool(value: inner, ..) -> collect_refs_expr(refs, inner)

    glance.RecordUpdate(
      module: mod_opt,
      constructor: ctor,
      record: rec,
      fields: fields,
      ..,
    ) -> {
      let refs = case mod_opt {
        Some(alias) ->
          Refs(..refs, qualified: set.insert(refs.qualified, alias))
        None -> Refs(..refs, unqualified: set.insert(refs.unqualified, ctor))
      }
      let refs = collect_refs_expr(refs, rec)
      list.fold(fields, refs, fn(r, f) {
        case f.item {
          Some(expr) -> collect_refs_expr(r, expr)
          None -> r
        }
      })
    }

    glance.TupleIndex(tuple: inner, ..) -> collect_refs_expr(refs, inner)

    glance.FnCapture(
      function: f,
      arguments_before: before,
      arguments_after: after,
      ..,
    ) -> {
      let refs = collect_refs_expr(refs, f)
      let refs =
        list.fold(before, refs, fn(r, field) {
          collect_refs_field_expr(r, field)
        })
      list.fold(after, refs, fn(r, field) { collect_refs_field_expr(r, field) })
    }

    glance.BitString(segments: segs, ..) ->
      list.fold(segs, refs, fn(r, seg) { collect_refs_expr(r, seg.0) })

    glance.Echo(expression: expr_opt, ..) ->
      case expr_opt {
        Some(inner) -> collect_refs_expr(refs, inner)
        None -> refs
      }

    // Literals — no refs
    glance.Int(..) | glance.Float(..) | glance.String(..) -> refs
    glance.Panic(..) | glance.Todo(..) -> refs
  }
}

fn collect_refs_field_expr(
  refs: Refs,
  field: glance.Field(glance.Expression),
) -> Refs {
  case field {
    glance.LabelledField(item: expr, ..) -> collect_refs_expr(refs, expr)
    glance.ShorthandField(..) -> refs
    glance.UnlabelledField(item: expr) -> collect_refs_expr(refs, expr)
  }
}

fn collect_refs_pattern(refs: Refs, pat: glance.Pattern) -> Refs {
  case pat {
    glance.PatternVariant(
      module: mod_opt,
      constructor: ctor,
      arguments: args,
      ..,
    ) -> {
      let refs = case mod_opt {
        Some(alias) ->
          Refs(..refs, qualified: set.insert(refs.qualified, alias))
        None -> Refs(..refs, unqualified: set.insert(refs.unqualified, ctor))
      }
      list.fold(args, refs, fn(r, f) {
        case f {
          glance.LabelledField(item: p, ..) -> collect_refs_pattern(r, p)
          glance.ShorthandField(..) -> r
          glance.UnlabelledField(item: p) -> collect_refs_pattern(r, p)
        }
      })
    }
    glance.PatternAssignment(pattern: inner, ..) ->
      collect_refs_pattern(refs, inner)
    glance.PatternTuple(elements: elems, ..) ->
      list.fold(elems, refs, collect_refs_pattern)
    glance.PatternList(elements: elems, tail: tail, ..) -> {
      let refs = list.fold(elems, refs, collect_refs_pattern)
      case tail {
        Some(p) -> collect_refs_pattern(refs, p)
        None -> refs
      }
    }
    glance.PatternBitString(segments: segs, ..) ->
      list.fold(segs, refs, fn(r, seg) { collect_refs_pattern(r, seg.0) })
    _ -> refs
  }
}

// ---------------------------------------------------------------------------
// Import-usage check
// ---------------------------------------------------------------------------

/// Returns True if this import contributes at least one used name.
fn is_import_used(imp: glance.Import, refs: Refs) -> Bool {
  let alias = import_alias(imp)
  let qualified_used = refs.qualified |> set.contains(alias)
  // Check if any unqualified value or type is used
  let unqualified_used =
    list.any(imp.unqualified_values, fn(u) {
      let name = u.alias |> option.unwrap(u.name)
      refs.unqualified |> set.contains(name)
    })
    || list.any(imp.unqualified_types, fn(u) {
      let name = u.alias |> option.unwrap(u.name)
      refs.unqualified |> set.contains(name)
    })
  qualified_used || unqualified_used
}

/// Returns True if this unqualified import name is actually referenced.
fn is_unqualified_used(u: glance.UnqualifiedImport, refs: Refs) -> Bool {
  let name = option.unwrap(u.alias, u.name)
  set.contains(refs.unqualified, name)
}

/// The effective alias for a module import (last segment, or explicit alias).
fn import_alias(imp: glance.Import) -> String {
  case imp.alias {
    Some(glance.Named(name)) -> name
    Some(glance.Discarded(name)) -> name
    None ->
      imp.module
      |> string.split("/")
      |> list.last
      |> result.unwrap(imp.module)
  }
}

// ---------------------------------------------------------------------------
// Source reconstruction
// ---------------------------------------------------------------------------

/// Rebuild the source file keeping only the given import lines,
/// preserving the leading header comment and all non-import body lines.
fn rebuild_source(original: String, kept_imports: List(String)) -> String {
  let lines = string.split(original, "\n")
  // Split into: header (leading comments/blanks before first import),
  // old import lines, and body lines (everything after all imports).
  let #(header, rest) = split_header(lines)
  let body = skip_imports(rest)
  let sorted_imports = list.sort(kept_imports, string.compare)

  let parts = case sorted_imports {
    [] -> list.flatten([header, body])
    _ -> list.flatten([header, sorted_imports, [""], body])
  }
  string.join(parts, "\n")
}

fn is_import_line(line: String) -> Bool {
  line |> string.trim |> string.starts_with("import ")
}

/// Take lines before the first `import` line (the generated comment header).
fn split_header(lines: List(String)) -> #(List(String), List(String)) {
  list.split_while(lines, fn(line) { !is_import_line(line) })
}

/// Drop all import lines and any blank lines that sit between them.
fn skip_imports(lines: List(String)) -> List(String) {
  list.drop_while(lines, fn(line) {
    is_import_line(line) || string.trim(line) == ""
  })
}

fn format_unqualified(u: glance.UnqualifiedImport, is_type: Bool) -> String {
  let prefix = case is_type {
    True -> "type "
    False -> ""
  }
  let alias = case u.alias {
    Some(a) -> " as " <> a
    None -> ""
  }
  prefix <> u.name <> alias
}
