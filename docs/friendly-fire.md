# Damage policy

All owners use TGC_fnc_damageDecision through TGC_fnc_isFriendlyFire. Friendly means identical side or victim-side getFriend >= 0.6. Player-controlled weapons use the human side. Enemy damage is allowed. This changes the former friendly-AI rule that rejected every player regardless of side.

TGC_fnc_damageSide retains vehicle allegiance without a crew and uses the configured vehicle side before first occupancy. Live crew determines capture. Every machine installs object handlers, and the owner alone enforces them. EntityCreated, EntityRespawned, Local and reconciliation cover lifecycle changes. Reconciliation restores last-handler position; mission player/vehicle callbacks also guard before secondary effects.

Fired stamps projectiles and keeps a bounded-by-ammo/side launcher record for 300 seconds. Guided missiles refresh target records every 0.25 seconds while in flight; those records expire after 0.75 seconds to avoid treating an unrelated later explosion as the same attack. Identical-ammo launches from different sides are ambiguous; do not guess a side from conflicting records. Placed charges retain projectile provenance. Collision evidence expires after 0.25 seconds.

Known friendly damage returns existing hit-index or overall damage before scaling, revive and critical effects. Direct scripted combat effects use TGC_fnc_applyCombatDamage on the target owner. Repair, state restoration, mission setup, cleanup and explicit self-destruction are separate mission operations, not combat damage.

## Limits and validation

HandleDamage does not intercept direct setDamage/setHit commands. External scripts/mods must use the combat API. Damage with neither usable actors nor unambiguous projectile/launcher/target/contact provenance is allowed and unresolved combat is logged at most once per victim per ten seconds. Engine-generated secondary explosions may lose responsibility; short collision evidence may be absent or overlap environmental damage. Projectiles in flight beyond 300 seconds lose launcher fallback; missiles continue to refresh target fallback. These are limitations, not proof of universal protection.

The one-second reconciliation cannot prevent an arbitrary later mod handler from temporarily overriding the final numeric result. Pre-effect guards cover the mission callbacks changed here. Network ordering, projectile deletion and physics require the multiplayer tests in tests/friendly-fire. This implementation must not be described as runtime-verified until that matrix passes.

## Direct scripted operations

Combat-derived player random hit-index damage and helicopter delayed rotor/fuel effects use the combat API. Their parent callbacks reject protected events before scheduling. The helicopter carries the original decision into delayed processing. Noncombat direct commands remain for repair/service and packed-state restoration; pre-injured rescue patients and revive lifecycle; AO/objective setup and cleanup; removal of abandoned enemy units; wreck/prop disposal; mine detonation and anti-projectile effects. These operations do not infer a combat attacker from the executing machine's player.

Owned asset retirement is the explicit player exception, centralized in canDestroyAsset: the player's UID must match the asset owner, the asset cannot be hidden, and no actual player may occupy it. Both nearby destruction and UAV self-destruct use it. Unowned base weapons cannot be retired through these actions. Secondary blast damage still passes through normal damage policy, subject to attribution limits above.

## Validation record

Codex ran the friendly-fire and friendly-AI source smoke checks and git diff --check. No SQF compilation or dedicated multiplayer combat run was performed. Run the supplied engine policy harness and complete the real-fire matrix before release. Arma's documented HandleDamage/Fired semantics: https://community.bistudio.com/wiki/Arma_3:_Event_Handlers ; last-handler inspection: https://community.bistudio.com/wiki/getEventHandlerInfo .
