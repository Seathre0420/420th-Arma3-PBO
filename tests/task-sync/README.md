# Task synchronization

Deploy the updated mission and `@apex/addons/apex_server.pbo` together, then restart
the mission. Clients do not need the server addon.

Deletion uses stock argument positions: `[id, owners, removeFromJIP, initialize]`.
The fourth argument is false for local removal. Full deletion retains a versioned
tombstone even when removeFromJIP is requested, preventing delayed resurrection.

Server snapshots carry complete BIS task attributes, monotonically increasing
revisions, and an AO generation. A single persistent snapshot replaces the previous
one. Clients reject older snapshots and process deletions before creations.
Main AO selection transfers to Defend of the same generation. Selecting another
task outside synchronization cancels the transfer. Empty/completed selections
also permit assignment. Existing valid selections survive updates and repairs.

Initialization, respawn and the existing 15-second task-manager interval request
snapshots. Missing owned tasks are recreated silently. Obsolete/no-longer-owned
tasks are removed. `[TaskSync] RESTORE` and `DEFEND_HANDOFF` log actual actions.

## Local validation

Run `./tests/task-sync/validate.ps1`. Checks cover delimiter balance, integration,
and packed/source equality; they do not execute SQF.
Run `./tests/task-sync/build-addon.ps1` to build an uncompressed PBO, or pass
`-VerifyOnly` to compare an existing build. The builder supplies the virtual prefix
and SHA-1 trailer. No server is launched.

## Server operator acceptance checks

1. With two stock clients, follow Main AO through normal, forced and Mega Defend.
   Defend must become selected for players following Main AO.
2. Select another active task on one client; preserve that selection while keeping
   Defend in its list. Test an empty selection too.
3. Select another task between AO deletion and Defend creation; preserve it. Finish
   an AO without Defend; a later AO must not inherit its selection transfer.
4. Join and respawn during transitions. Check ownership, duplicate prevention and
   restoration by the next 15-second check.
5. Locally remove the Main AO simple task while leaving server state intact.
   Reconciliation must silently restore it and preserve another valid selection.
6. Exercise repeated AO IDs. Replay an old captured snapshot locally after a newer
   snapshot, including after respawn; it must not change current tasks.
7. Verify SUCCEEDED, FAILED, CANCELED, parent/child deletion and partial owner
   removal. Remaining owners must retain their tasks and registry metadata.
8. Check RPTs for errors and unexpected deletion broadcasts. Stock clients must
   not initiate global deletion in response to a server task removal.

No server or multiplayer tests were performed during implementation.
