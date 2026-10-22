# Defend rotation validation

Run `node tests/defend-rotation/validate_source.cjs` for source integration checks.
The engine harness compiles the marked production blocks from `fn_core.sqf`;
it checks rotation sequences and overrides without spawning combat units.
Run `validate_engine.sqf` server-locally in a standalone editor mission with
the repository's `Apex_framework.terrain` folder available. Expect
`[Defend rotation test] COMPLETE failures=0` and no script errors in the RPT.
The harness refuses an initialized framework and restores its namespace inputs.

On an Arma test server, verify:

- Complete an eligible AO and let Defend start. Finish or fail that Defend.
  Complete the next AO: no automatic Defend; HQ remnants clean up normally.
- Complete another AO: normal Defend entry checks apply again.
- During a blocked AO, separately test Queue Defend, Force Defend and Mega
  Defense. Each should start and block automatic Defend after the next AO.
- A rejected Defend attempt or cancelled Mega Defense request must not block
  the next AO. A cycled AO or AO with Defend disabled consumes the intervening AO.
- Pause/resume without selecting another AO must not advance rotation history.
- Restart the mission: the first AO has no inherited restriction.
