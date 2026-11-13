# Combat Lab v0.5.3.2 implementation and validation

Implementation for #29, #26, #27 and #28. Owner acceptance remains pending. No merge or deployment is authorised.

## Rules audit checkpoint

`CombatEngine` captures actual dice at evaluation time. `RulesMath.damage_roll` returns dice and formula modifiers without changing the existing RNG sequence. `combat_audit.gd` renders stable event IDs, round/turn, actor/target, rolls, modifiers, DC/AC, outcomes, triggers and consequences. Structured events remain authoritative; previews and speculative AI search never emit events. Explicit rejected commands now append rejection facts without spending resources. The full log reconstructs all authoritative text, independent of the sidebar.

Giant spider fixture now declares typed `traits.web_walker`. Verified against the [official SRD 5.2.1](https://media.dndbeyond.com/compendium-images/srd/5.2/SRD_CC_v5.2.1.pdf), giant spider pp. 353–354. This milestone's deliberately narrow adaptation ignores Web terrain cost only, retains other difficult terrain and still resolves Web saves and source-owned Restrained. It adds no spell immunity or Web Sense subsystem; the Lab archetype is not a complete SRD stat block.

This work includes material from the System Reference Document 5.2.1 (“SRD 5.2.1”) by Wizards of the Coast LLC, available at https://www.dndbeyond.com/srd. The SRD 5.2.1 is licensed under the Creative Commons Attribution 4.0 International License, available at https://creativecommons.org/licenses/by/4.0/legalcode. Action summaries and Web Walker behaviour are adapted as described above; Burning propagation remains the existing Lab house rule.

## Action controls checkpoint

Pending actions live only in `CombatLab`; engine actions stay irrevocable. First press selects; second distinct press or Confirm revalidates and commits once. Cancel, another action, actor/turn change, Retry/title discard the intent. Multiple restraints require an explicit source selection. Engine `action_info` supplies schema-versioned live costs, duration, effect, consequences and legality; `action_explanation.gd` renders them without evaluating rules. Attack/spell target taps retain their confirmation behaviour; Web retains its existing deliberate point confirmation.

Dash/Disengage select Move after committing only when movement is legal. Move displays remaining feet and spends movement, independently of Action. Dodge and Disengage show Active/Action used; other utility buttons show Ready/Pending/Used/Disabled in text. Physical touch releases are handled separately from compatibility mouse events; drag, multi-touch and keyboard echo cannot confirm. Tab/focused buttons and Enter/Escape provide keyboard controls.

## Validation evidence

Verified with checksum-pinned Godot `4.5.2.stable.official.6ce3de25a` on Linux. The host's preinstalled 4.6.3 was not used; project/toolchain pins remain 4.5.2.

| Check | Result |
| --- | --- |
| All 33 existing + 3 new Godot suites registered in `godot-smoke.yml` | **PASS**, all 36 exit 0; no script/assertion failures |
| `godot --headless --path . --editor --quit` | **PASS**, no parse/import errors |
| `godot --headless --path . --quit-after 30` | **PASS** |
| `python3 scripts/self_test.py` | **PASS**; expected negative-path “Godot not installed” diagnostic is part of its test |
| `python3 scripts/validate_toolchain.py` | **PASS** |
| `python3 scripts/validate_template.py --project` | **PASS** |
| `python3 scripts/test_codespaces_web_preview.py` | **PASS**, both tests, including local HTTP during build |
| Godot 4.5.2 `--export-release Web build/web/index.html` | **PASS**, nonempty HTML, JS, WASM and PCK; official templates SHA-256 verified |
| Local private `127.0.0.1:8765` Chromium Web smoke | **PASS**, HTTP 200, one canvas, no page/console errors; title, deployment, battle and pending Dash inspected |
| Browser layout, 1366×1024 and 768×1024 | **PASS** for inspected Dash explanation, visible Confirm/Cancel, fixed command bar and battlefield; native viewport sizing removes portrait letterboxing |
| Actual Codespaces inventory/forwarding | **NOT VERIFIED**: read-only `gh codespace list --repo Jonty303/Project-AzureMines --json name,state` returned Forbidden; no Codespace created/resumed |
| Physical iPad Safari, gamepad, audio/balance and owner acceptance | **NOT RUN** |

The new suites cover captured save/attack dice/modifiers/DC/AC, exact consequence/event rendering, deterministic seed replay, preview/search purity, real spider fixture terrain/save behaviour, all six cancellable intents, duplicate confirmation/revalidation, explicit overlapping restraint sources, resource snapshots, truthful states, lifecycle cleanup, full-log completeness, viewport/control bounds, simulated touch/mouse compatibility, drag/multitouch and keyboard input.

Baseline diagnostics are disclosed rather than counted as clean runtime output: resource/ObjectDB cleanup warnings occur in the older audio/context, deployment, Lab UI, wide-camera and intermittently movement/impact suites; the older Lab UI suite also opens two exclusive dialogs. These suites exit 0 and report PASS; the same resource/exclusive-dialog diagnostics reproduce on untouched base `a3f38f5`. Import/startup and the new suites are clean. Initial sandbox-only socket/data-directory failures were resolved by using writable XDG directories and local socket permissions, without changing game code for those failures.

Screenshots: [landscape](validation/v0532-landscape.png), [portrait](validation/v0532-portrait.png). These are desktop Chromium evidence, **not physical touch acceptance**.

Known limits: the Lab still implements only its existing bounded combat rules and fixture mechanics; no new immunity/resistance system, Web Sense, monster abilities or spells were invented. Web Walker is the narrow movement-cost adaptation requested in #29, with saves/Restrained preserved. Human visual readability, Safari gesture feel and numerical balance require the script below. Details remains optional and presentation-only.

## Physical iPad acceptance script

Use the current branch's private port 8765 preview. Record commit, iPad model, iPadOS and Safari version. Test landscape and portrait:

1. Dash → Cancel: no Action or movement grant. Dash → Confirm → Move: one Action, correct extra feet; cancel Move without refund.
2. Disengage → Cancel, then Confirm → Move past a threatened cell: no opportunity attack; remaining feet truthful.
3. Dodge → Cancel/Confirm: active defence, Action used. Second Wind → Cancel/Confirm: Bonus Action, HP/use update once.
4. Web-restrained actor: choose exact source/DC when overlapping; Escape → Cancel/Confirm, inspect roll/result. Burning actor: Extinguish → Cancel/Confirm, inspect Action/status.
5. Select each action and inspect Cost/Effect/Duration/Consequence, Details, disabled reasons and live spell slots. Attack/spells keep target-tap commitment; Web keeps same-point second tap/Confirm.
6. One touch must never double-confirm via synthetic mouse. Drag, pinch, pan, scroll, Retry, actor/turn change and title must discard stale intent/targets.
7. Giant spider enters/starts in Web: full log shows d20, +3 Dexterity, DC, result, source-owned restraint and narrow Web Walker terrain reason. Other actors pay difficult terrain.
8. Full log: scroll to earliest and latest entries. Confirm controls stay visible, text wraps, battlefield and bottom command bar remain usable in both orientations.
