# Combat Lab v0.5.3.2 — Codex handoff: Combat Clarity & Action Controls

**Status:** Ready for implementation; no v0.5.3.2 gameplay has been implemented or accepted.  
**Canonical task:** [GitHub Issue #29](https://github.com/Jonty303/Project-AzureMines/issues/29)  
**Related defects:** [#26 comprehensive combat log](https://github.com/Jonty303/Project-AzureMines/issues/26), [#27 Dash/Move](https://github.com/Jonty303/Project-AzureMines/issues/27), [#28 cancellable actions](https://github.com/Jonty303/Project-AzureMines/issues/28)  
**Prepared branch:** `feature/combat-lab-v0532-combat-clarity`, based on v0.5.3.1 head `a3f38f5066784f7b87e6457e86b53c9964b845a4`  
**Draft PR target:** `feature/combat-lab-v0531-targeting-combustion`, **not** main.

## Goal

Make every resolved rules check intelligible in the full battle log and prevent accidental expenditure of Actions/Bonus Actions by one-tap controls. Correct the relationship between Dash/Disengage and Move; investigate giant-spider Web Walker behaviour without inventing blanket spell immunity.

## Implementation checkpoints

1. **Combat audit events and readable log:** Instrument central rule resolvers, capture actual dice/modifier/DC/AC and results, render readable log with stable event IDs. Include Web DEX success/failure, skipped checks, concentration, AoO, damage, death saves, AI committed decisions, resource changes and explicit invalid commands. Never generate logs from pure hover, preview or speculative AI/pathfinding.
2. **Pending-action UI:** Ready → Pending → Committed/Used/Active for Dash, Disengage, Dodge, Second Wind, Escape and Extinguish. A second distinct tap or explicit Confirm commits; Cancel/other action clears without spending. Synthetic mouse after touch must not double-confirm. Revalidate before committing. Escape should identify/select its restraint source.
3. **Move and state clarity:** Dash/Disengage confirm then activate Move targeting if legal. Keep Move visible and enabled with actual remaining movement. Cancelling movement targeting never refunds committed Dash/Disengage. Preserve single-tap End Turn and target-confirmed Attack/spells; Web's separate two-tap target/confirm remains.
4. **Spider/Web Walker:** Verify trait data/rules, implement narrowly for movement through Web only if appropriate. Continue Web DEX saving throws/Restrained unless the actual rules provide otherwise. Log all outcomes and reasons.
5. **Regression and handover:** New `test_v0532_*.gd` suites in Godot runtime CI; run pinned Godot 4.5.2, all old suites, Web export, Codespaces browser smoke, governance and runtime CI at final pushed SHA. Physical iPad acceptance NOT RUN until owner playtest. Commit/push recoverable checkpoints, open a draft PR against v0.5.3.1; no merge or Pages deploy.

## Key existing code

- `scenes/combat_lab.gd` immediately calls `engine.use_dash()`, `use_disengage()`, `use_dodge()`, `use_second_wind()`, `escape_effect()`, `extinguish()` from first tap. Dash/Disengage then set `action_mode="move"`. Add UI pending intent **before** these authoritative calls, not an engine-side undo.
- `combat/combat_engine.gd::effect_hook()` emits `effect_applied` for Web DEX checks but not a human-readable combat-log line. It already knows `total` and `dc`; capture roll/modifier details at check time.
- Preserve v0.5.3.1 central targeting, obstacle masking, Web fire propagation, Burning and existing touch/bonus-action state.

## Acceptance script for iPad

On private Codespaces port 8765, try Dash → Cancel, Dash → Confirm → Move; Disengage → Cancel, Disengage → Confirm → Move away from a threatened square; then Dodge, Second Wind, Escape and Extinguish (where available). Confirm the first tap spends nothing, the second/Confirm spends once, and Move remains truthful. Test Web on a giant spider and read the **full** log for the save, DC, result, restraint, movement cost and any trait. Verify pinch/pan/scroll and Retry/turn changes clear pending actions. Report device/browser, screenshot and failures; no headless test is physical acceptance.

For complete implementation and regression detail, **read Issue #29**. Do not add unrelated spells or broaden the combat engine's scope.
