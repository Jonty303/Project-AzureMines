# Data contracts — v0.1

## Ruleset manifest

`rulesets/<id>/manifest.json` has `schema_version`, `id`, `name`, `level_min`, `level_max`, `class_ids`, `race_ids`. The prototype does not yet validate all schema fields.

## Adventure manifest

`adventures/<id>/manifest.json` has `schema_version`, `id`, `title`, `ruleset_id`, `starting_location`.

Starting location is resolved from `adventures/<id>/locations/<starting_location>.json`.

Only lower-case ASCII letters, numbers and underscores are accepted in file-backed identifiers. Untrusted input is not allowed to form arbitrary paths.

## Contracts to implement next

- Versioned JSON schema with detailed diagnostics, required fields and uniqueness checks.
- Cross-file reference validation for quests, encounters, maps, loot and creatures.
- Definition identifiers namespaced by ruleset and content pack, such as `classic_5e:spell/magic_missile`.
- Distinct **definitions** (immutable authored data) and **instances** (character HP, uses, locations, effects).
- Content compatibility and migration policies for changing definitions and saves.
- Typed effect definitions, no executable scripts inside adventure data.
- Explicit licence and attribution metadata for distributable content packs.

## No misleading implementation claims

`classes.json` and `races.json` currently describe **design choices only**. They are not yet full rule definitions, and the combat engine is not implemented.
