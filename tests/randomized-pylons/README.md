# Randomized pylon validation

Run the reference consistency check from the repository root:

```powershell
python tests/randomized-pylons/validate_allowlist.py
```

This verifies the runtime allowlist matches all 35 reviewed classnames in the
SQF, Markdown, and JSON references, including the retained KH25/Sharur and
GBU-12/Mk82 variants. It does not run SQF or replace an Arma engine test.

For the engine test, copy `validate_engine.sqf` into a disposable copy of the
mission as `tests/randomized-pylons/validate_engine.sqf`. After mission
initialization, execute locally from the debug console:

```sqf
[] execVM "tests\randomized-pylons\validate_engine.sqf";
```

Use a disposable editor or Server Lab session: this temporarily empties and
restores the local cached pylon allowlist while testing empty candidates. It
creates and deletes its own local aircraft. Inspect the RPT for
`[QS PYLON TEST] Complete: 0 failures` and check for SQF errors.

The engine test covers single-pylon/all-pylon query agreement, membership in the
allowlist, native compatibility, the helicopter AA filter, selection on eight
repeated loadouts, retained KH25/Sharur/Mk82 eligibility, empty candidate sets,
and an aircraft without pylons. Run with Creator DLC loaded to confirm its
compatible magazines cannot enter the selected loadouts. Preset mode and the
normal AO/defend bomb-stripping behavior are outside this test's scope.
