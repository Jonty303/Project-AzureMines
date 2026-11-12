# PR 15 isolated iPad preview

## Purpose and approval
On 12 November 2026 the owner approved publishing a separate playtest preview of PR #15 while keeping the existing playable build and `main` unchanged. This authorises preview packaging/deployment, not merging PR #15 or accepting its gameplay.

## Source and addresses
- Gameplay source: `f41eba85eaabf9c81dbf38899c8b41b690b13c07` on `codex/issue-14-tactical-ai`.
- Packaging branch: `feature/pr15-ipad-preview`.
- Preview: https://jonty303.github.io/Project-AzureMines/previews/pr-15/
- Existing game: https://jonty303.github.io/Project-AzureMines/
- Original deployed source: `950b41ee1203f7dcb607c38eb1ae0c70a57a7b9b`, successful web workflow run `43255328775`, artifact `combat-lab-web-build`.

## Implementation and preservation
GitHub Pages deploys a complete site artifact. The dedicated preview workflow retrieves the original stable web artifact, verifies its file hashes against the public site, and copies those files without recompiling or editing them. Only `previews/pr-15/` is added. The combined artifact is deployed and public SHA-256 checks verify both the existing files and the preview assets. Source refs for `main`, `feature/combat-lab-web-touch`, and the Codex implementation remain untouched.

The preview uses an HTML header with the PR, version and gameplay commit, and an iframe for the ordinary Godot Web export. Its only build-time GDScript packaging adjustment changes `LAST_REPORT_PATH` to `user://combat_lab_pr15_last_battle.json`, preventing a playtest from overwriting the existing build's last-battle report. No rules, fixtures, AI, project configuration or action economy are changed by packaging. All regression scripts run after this adjustment. The public `build.json` records this difference and file checksums.

## Human instructions
Use iPad landscape. Confirm the header says `PR #15 · v0.4.3 TEST PREVIEW` and `f41eba85eaab`. Test mixed enemy movement around the wagon, hazards, Brunna's opportunity-attack probe with and without Disengage, accepting/declining reactions, exhausted spell actions/slots, blocked-target hints and bonus-action healing. Recheck downed turns and projectile/collapse timing. Record arena, roster, level, seed, round, device/browser and screenshots for failures. Physical-device acceptance is NOT RUN until the owner records it; neither a web export nor HTTP verification proves Safari/WebGL gameplay.

## AI agent instructions
Do not merge, force-push or advance live source branches. Keep deployment pinned to the reviewed source. Guards reject changed PR or stable heads. Import, startup and all 20 regression scripts must pass; script errors fail the preview workflow. Known resource-cleanup and exclusive-dialog diagnostics in existing tests remain visible in evidence and are not a claim of error-free release acceptance. Do not silently add exceptions or infer that these diagnostics predate PR #15.

## Reproduction and limitations
The workflow runs only on its isolated packaging branch or an explicit dispatch. It uses the repository's existing pinned Godot 4.5.2 editor/templates and official Actions already used for publishing, plus the official artifact download action. Build/test logs and preservation metadata are retained in `pr15-preview-evidence`.

The original web artifact expires on 26 November 2026; recreating this exact packaging after expiration requires a preserved verified copy or a separately reviewed replacement. A later normal stable-site deployment will remove this preview subdirectory because the existing publishing workflow has deliberately not been changed. This is a one-off playtest deployment, not a general automatic PR-hosting service.

Rollback: rerun the existing successful stable publishing workflow to restore the original single-build site, after confirming its source. This is not an instruction to roll back now.

## Verification record
Local packaging fixtures, Python syntax and workflow shell/YAML parsing were checked before submission. Actual Godot execution, web export and public hash verification are recorded by the new workflow run; do not mark them PASS until that run succeeds. Desktop graphical, physical iPad and controller acceptance remain separate.
