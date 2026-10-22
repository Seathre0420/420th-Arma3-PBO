const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..', 'Apex_framework.terrain');
const read = name => fs.readFileSync(path.join(root, 'code/functions', name), 'utf8');
const owner = read('fn_engineerRepairOwner.sqf');
const client = read('fn_clientEngineerRepair.sqf');
const hook = read('fn_clientInGameUIAction.sqf').split("if (_QS_actionName isEqualTo 'RepairVehicle') exitWith {")[1].split("if (_QS_actionName isEqualTo 'UseMagazine')")[0];
assert(!/setFuel|setVehicleAmmo|tail_rotor_hit/i.test(owner + client + hook), 'Repair must neither alter fuel/ammo nor instantly fix the rotor');
assert(owner.includes('remoteExecutedOwner != owner _unit'), 'Owner must validate the requester');
assert(owner.includes('isNil {'), 'Damage read/write must be atomic');
assert(hook.includes('spawn QS_fnc_clientEngineerRepair'), 'Native action must route to gradual repair');
for (const name of ['engineerRepairOwner', 'engineerRepairEligible', 'clientEngineerRepair']) {
  assert(fs.readFileSync(path.join(root, 'description.ext'), 'utf8').includes(`class ${name} {`));
}
// Independent acceptance model: pausing costs no work, and resuming must not
// change total active time. This is the timing contract, not an SQF engine test.
const work = d => 240 * d ** 1.5;
const remainingDamage = (d, seconds) => (Math.max(0, work(d) - seconds) / 240) ** (2 / 3);
for (const [damage, seconds] of [[0.05, 3], [0.25, 30], [0.5, 85], [0.9, 205]]) {
  assert(Math.abs(work(damage) - seconds) < 1);
  const afterFirst = remainingDamage(damage, work(damage) / 3);
  const afterResume = remainingDamage(afterFirst, work(damage) / 3);
  assert(Math.abs(work(afterResume) - work(damage) / 3) < 1e-8);
  assert.equal(remainingDamage(damage, work(damage)), 0);
}
console.log('Engineer repair source and timing contracts passed. Arma multiplayer validation still required.');
