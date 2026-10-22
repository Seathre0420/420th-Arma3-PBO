# Role synchronization regression checks

Run `node tests/role-sync/validate_source.cjs` from the repository root. This
checks structural delimiters and integration guards; it does not execute SQF.

Deploy the complete mission update together: the role RPC payloads have changed.
Use a dedicated multiplayer server, a Staff account, and an ordinary account.
Compare raw `QS_unit_role`, `QS_roleState`, traits, menus and map tooltips on the
owner, server, and observer. ROLE ASSIGN and ROLE REJECT entries appear in RPTs.

| Scenario | Required result |
| --- | --- |
| Select roles, accept a queue, force Rifleman through Staff | Server records the new assignment, client applies traits/loadout once, observer labels converge within the existing 5–15 second refresh interval. Logs identify the reason and Staff UID. |
| Send case 16 or 121 from another client | Rejected; target role, equipment, queue actions and position remain unchanged. Origin rejection logging is throttled. |
| Deliver an older server assignment after a newer one, then duplicate the newer assignment | Older revision is rejected; duplicate does not reset equipment or repeat hints. |
| Respawn and deliver messages addressed to the old unit | Messages and delayed arsenal work cannot affect the replacement unit. Existing role, side and connection session survive; the replacement receives a fresh revision. |
| Switch roles rapidly during the two arsenal delays | Final arsenal data and traits match the last assignment. |
| Queue for a role, respawn, then deliver old queue events | Old object messages cannot clear new actions or teleport the replacement unit. Current queue reissue and acceptance still work. |
| Delay login responses beyond ten seconds; repeat requests concurrently | One default assignment and one client initialization. Retries resend the cached acknowledgment. Existing role selections survive. |
| Spoof another player's login unit, owner or UID | Server rejects the request. |
| Disconnect/reconnect the same UID | New connection gets a fresh session. Messages and initialization work from the old connection have no effect. |
| In CAS mode 3, switch Fighter Pilot to Staff before the last jet is destroyed | Staff remains Staff; old jet cannot trigger a demotion. |
| Exhaust allowance while still Fighter Pilot | One Rifleman assignment and respawn; switching role before queued processing or during delayed respawn cancels obsolete work. |
| Fighter Pilot respawns while their jet still exists | Aircraft ownership snapshot follows the replacement unit; normal allowance enforcement remains functional. |
| Simulate local role-field drift | Periodic repair restores the accepted role without reapplying loadout. Recovery requests are bounded and never assign a default role. |

The server owns assignment snapshots `[unit, UID, session, revision, side, role]`.
Client acknowledgments are connection-bound. Revisions are monotonic for the
mission lifetime. The periodic recovery request handles missed assignments and
the early respawn interval where `player` may still reference the old object.
