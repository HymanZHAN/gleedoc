# Changelog

## [0.6.0] - 2026-05-21

### <!-- 0 -->🚀 Features

- Extract module-level doc comment
- Source-mapped doc test
- Auto format generated test files
- Auto format generated test files
- Single `gleam test` experience
- Support the `ignore` attribute
- New `preserve_tests` config option

### <!-- 1 -->🐛 Bug Fixes

- Incompatible code format in doc
- Incorrect doc test
- Doc-test out-of-sync issue with env-var-guarded re-invocation of `gleam test`
- Cli entry point should preserve tests

### <!-- 3 -->📚 Documentation

- Refine README
- Update README

### <!-- 6 -->🧪 Testing

- Module-level doc extraction IT
- Default helper UT

### <!-- 7 -->⚙️ Miscellaneous Tasks

- Format code snippet in docs
- Test formats
- Prepare release script

## [0.5.0] - 2026-05-17

### <!-- 0 -->🚀 Features

- Introduce new config option `preludes`

### <!-- 2 -->🚜 Refactor

- Minor clean up of `parse.gleam`
- Replace sequential list.append with list.flatten
- Minor adjustment and comments
- Rename `preludes` to `extra_imports`

### <!-- 3 -->📚 Documentation

- Fix incorrect test file name
- Cross out irrelevant entry
- CHANGELOG.md (with git-cliff)
- Update doc on `GleedocConfig` and roadmap

### <!-- 6 -->🧪 Testing

- Adapt for `preludes`; new test cases

## [0.4.0] - 2026-05-16

### <!-- 0 -->🚀 Features

- Adaptation for Windows line breaks

### <!-- 1 -->🐛 Bug Fixes

- Revert CLRF handling
- Format of doc code blocks
- Format of doc code blocks
- Generated tests should be as `gleam format`-compliant as possible

### <!-- 2 -->🚜 Refactor

- Move fixtures to dev dir; fix js target resolve path

### <!-- 3 -->📚 Documentation

- Update dev guide and roadmap
- Update README

### <!-- 6 -->🧪 Testing

- Format generated test files
- Adapt UT

### <!-- 7 -->⚙️ Miscellaneous Tasks

- Remove format test as generated tests might still contain incorrect formats
- Update deps
- Version bump

## [0.3.0] - 2026-05-13

### <!-- 0 -->🚀 Features

- Remove unused imports

### <!-- 1 -->🐛 Bug Fixes

- Move test preparation script to dev

### <!-- 3 -->📚 Documentation

- Update README

### <!-- 7 -->⚙️ Miscellaneous Tasks

- Version bump

## [0.2.0] - 2026-05-13

### <!-- 1 -->🐛 Bug Fixes

- Use `filepath` to handle file path

### <!-- 3 -->📚 Documentation

- Update README

### <!-- 6 -->🧪 Testing

- Add test preparation script

### <!-- 7 -->⚙️ Miscellaneous Tasks

- Version bump

## [0.1.0] - 2026-05-12

### <!-- 0 -->🚀 Features

- Init commit
- Shorten generated test names and test file names
- Include current module's imports by default

### <!-- 1 -->🐛 Bug Fixes

- Duplicate imports
- Minor code clean up
- Incorrect unqualified type in imports
- Incorrect generated unqualified imports order

### <!-- 2 -->🚜 Refactor

- Clean up extract.gleam
- Clean up generate.gleam
- Clean up parse.gleam
- Clean up scan.gleam
- Rename doc test path to `gleedoc`; add real integration tests
- `gleedoc_xxx_test` to `xxx_gleedoc_test`

### <!-- 3 -->📚 Documentation

- Fill gleam.toml
- Update README
- Update README

### <!-- 6 -->🧪 Testing

- Enhance fixtures and extract_test; use more idiomatic `assert` style
- New fixture (gleam/int), new integration tests

### <!-- 7 -->⚙️ Miscellaneous Tasks

- Code format
- Set version to 0.1.0
- Codebook.toml
- Rm old tests
- Just use plain `assert`
- Update CHANGELOG; include known issues

