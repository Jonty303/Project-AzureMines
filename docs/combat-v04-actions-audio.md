# Combat v0.4 — Contextual Actions, Reactions and Sound

**Branch:** `feature/downed-sprites-action-bar`. This is a continuation of the level-1 tactical prototype, not a new ruleset or character-level milestone.

## Contextual targeting (explicitly requested)

- **Move:** only selectable reachable squares are highlighted, in muted party blue. No attack or spell highlights.
- **Attack:** only living enemies that can be attacked with the **selected weapon** are highlighted, in red. No movement or spell highlights.
- **Spells:** only valid targets for the **selected spell** are highlighted, in gold. No weapon or movement highlights.
- **No action selected, or Action spent / movement exhausted:** no inappropriate ranges are shown.
- When movement reaches zero, **Move** is disabled and crossed out. When Action is spent, Attack, Dash, Dodge and Disengage are disabled and crossed out. Spells are crossed out only when no eligible cast remains (a Bonus Action spell may still be legal after an Action).
- Buttons that are irrelevant to a class (e.g. Second Wind on the Priest) are disabled without pretending the player has spent the corresponding resource. End Turn remains available.

Range previews are calculated in `combat/combat_board.gd::get_highlights()` and tested independently of rendering. Movement is performed only from **Move** mode; an invalid click never moves the character or spends a resource.

## Level-1 combat systems

- **Opportunity Attacks:** movement now advances tile by tile; leaving an enemy's 5-foot reach can trigger a melee reaction before the move completes. Enemy reactions resolve automatically, while the player gets **Attack / Decline** controls. A Reaction is consumed when used and restored at the start of the actor's next turn.
- **Disengage:** spends Action and suppresses Opportunity Attacks caused by that character's movement for the turn.
- **Shield:** Elyra may use a Reaction and level-1 slot when hit by an ordinary attack roll. Her AC increases by 5 until the start of her next turn, potentially deflecting the triggering attack.
- **Bless:** Brunna may concentrate on Bless for up to 10 turns, granting 1d4 to the chosen target and up to two automatically selected nearby allies' attack rolls and saving throws. Damage provokes Constitution concentration checks; expiration or failure clears the effect.
- **Reactive UI:** when a pending reaction pauses an enemy turn, the game waits for the player to accept or decline, then resumes its interrupted resolution.
- The immutable level-1 party fixture is unchanged.

## Original audio (no external samples)

Eight original, procedurally synthesised **16 kHz mono, 16-bit WAV** clips are committed in `assets/sfx/`. These are intended as temporary production-friendly SFX placeholders and can be replaced without changing the rules engine.

| File | Trigger |
| --- | --- |
| `footstep.wav` | A successful movement step (gravel/boot crunch) |
| `melee_hit.wav` | A successful melee strike (metal clang) |
| `ranged.wav` | A successful ranged weapon attack (string twang) |
| `magic.wav` | An executed spell (magical zap) |
| `heal.wav` | A healing spell or Second Wind (original short flourish) |
| `miss.wav` | A missed/deflected attack (swish) |
| `damage.wav` | HP damage on a successful hit (synthesised grunt) |
| `death.wav` | A combatant reaches a dead/downed state (falling vocal-like cry) |

Audio is event-driven, rather than tied to UI clicks. The scene uses one `AudioStreamPlayer` per effect, at approximately -12 dB. To avoid audio spam, each unique cue is played at most once during a single UI refresh, with at most three different simultaneous cues. Import/load and event dispatch are covered by headless tests; perceived loudness and mixing **still require a desktop audio playtest**.

## Test coverage

The GitHub Actions Godot 4.5.2 suite includes:
- `tests/test_audio_and_contextual_ui.gd` — WAV imports, movement cue, action-only targeting, exhausted button state.
- `tests/test_reactions_and_disengage.gd` — movement pause/accept/decline and no Opportunity Attack after Disengage.
- `tests/test_shield_and_bless.gd` — Shield's Reaction, spell slot, temporary AC and Bless's targets/concentration.
- The existing scene, party fixture, attack maths, spell resources and complete-encounter tests.

## Known limitations / next rules pass

- Shield is currently prompted by **normal attack hits**, not by a Magic Missile targeting event or an Opportunity Attack. Full Reaction interruption generalisation remains work.
- Bless auto-chooses two nearest eligible allies beyond the clicked target rather than allowing manual selection of all three. Future targeting UI should expose each target explicitly.
- Full rule-correct cover, Hide, Help, Ready, Sneak Attack on other creatures' turns, timed weapon mastery effects, full 0-HP damage/death edge cases and all prepared level-1 spells remain unfinished.
- Ray of Frost currently does damage but does not reduce Speed. Some other class/racial features await a scenario that exercises them.
- The training encounter is still **four heroes vs two goblins**. A larger four-goblin test should follow once the current reaction interactions have had a manual playthrough.
- No loot/economy changes are made in this iteration.

The battle UI, audio levels, reaction dialogs and initial asset seams have to be evaluated in the **actual Godot desktop window** before this draft work is merged.
