# Architecture — v0.1

## Design goal

Build a Gold Box-inspired RPG with **three independent layers**:

1. **Engine:** Godot presentation, navigation, tactical grid, command processor, event log, save system, dialogue widgets and encounter orchestration. It does not hardcode a goblin, class progression or a particular quest.
2. **Ruleset:** Classes, racial traits, level progression, equipment, spells, creatures, combat effects and mechanical adjudication.
3. **Adventure:** Maps, locations, dialogue, quests, NPC identities, encounters, rewards and story flags, referencing compatible ruleset identifiers.

The **runtime integration** loads adventure manifests, checks required ruleset and resolves references.

## Runtime boundaries

- Do not import adventure-authored GDScript or execute arbitrary expressions from JSON.
- Use versioned manifest schemas, stable IDs and explicit ruleset dependencies.
- Engine accepts validated commands and produces immutable-style result events; presentation animates the events.
- Combat state and dice must be testable without graphical scenes or user input.
- Save serializable game state (IDs, locations, party, turn/effect state); avoid saving raw Nodes.
- Adventure content uses generic event/interaction definitions, not copies of combat algorithms.
- Prefer a Godot-native UI and GDScript for version 1. No addons required for bootstrapping.

## Planned combat flow

```text
Player/AI intent -> Command validation -> Rules resolution
                                      -> Reaction/interrupt decisions
                                      -> State updates + event log -> Godot scene
```

Movement should resolve tile by tile and permit an opportunity attack interrupt before leaving reach.

## Current code

The bootstrap intentionally implements only a minimal JSON module loader, dice utility and UI shell. Rule adjudication, actor state, input routing, combat turns and adventure triggers are future work.

## Suggested implementation boundaries

```text
core/             module_loader, dice, future game state / event bus
combat/           future state, commands, resolver, effects, reactions, AI, grid
characters/       future creation, class progression and party roster
exploration/      future grid exploration and interaction/event runtime
rulesets/classic_5e/
adventures/test_adventure/
scenes/
tests/
```

The filesystem layout is a starting point, not a public plugin API.
