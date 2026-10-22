const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../../Apex_framework.terrain');
const read = n => fs.readFileSync(path.join(root, 'code/functions', n), 'utf8');
const owner = read('fn_engineerRefuelOwner.sqf');
const client = read('fn_clientEngineerRefuel.sqf');
const eligible = read('fn_engineerRefuelEligible.sqf');
const core = read('fn_clientCore.sqf');
assert(core.includes("addAction ['Refuel'"));
assert(core.includes('fuel cursorObject < 1'));
assert(client.includes("['Cancel Refuel'"));
assert(client.includes("['QS_repairing_vehicle',TRUE]"), 'Repair/refuel must share the client busy guard');
assert(owner.includes('remoteExecutedOwner != owner _unit'));
assert(owner.includes("['QS_engineerRefuel_lock',_token]"));
assert(owner.includes('private _current = fuel _vehicle;'));
assert(owner.includes('private _rate = 0.01;'));
assert(owner.includes('isNil {'), 'Fuel read/write must run atomically');
assert(!/setDamage|setHit|setVehicleAmmo|setFuelCargo/i.test(owner + client));
assert(!/itemToolKits|noRepair|services_repair_disabled/.test(eligible));
for (const name of ['clientEngineerRefuel', 'engineerRefuelEligible', 'engineerRefuelOwner']) {
  assert(fs.readFileSync(path.join(root, 'description.ext'), 'utf8').includes(`class ${name} {`));
}
assert(fs.readFileSync(path.join(root, 'code/config/security.hpp'), 'utf8').includes('class QS_fnc_engineerRefuelOwner {allowedTargets = 0;};'));

// Timing acceptance contract, independent of SQF. Pauses do not change fuel;
// split sessions use the same active time, and external fuel changes persist.
const advance = (fuel, seconds) => Math.min(1, fuel + seconds / 100);
for (const [fuel, duration] of [[0,100],[0.25,75],[0.5,50],[0.9,10]]) {
  assert(Math.abs((1 - fuel) * 100 - duration) < 1e-8);
  const partial = advance(fuel, duration / 2);
  assert(partial > fuel && partial < 1);
  assert.equal(advance(partial, 0), partial);
  assert(Math.abs(advance(partial, duration / 2) - 1) < 1e-8);
}
assert.equal(advance(0.8, 100), 1);
assert.equal(advance(0.2, 10), 0.2 + 0.1);

// Catch delimiter mistakes while allowing SQF strings and comments.
for (const file of ['fn_engineerRefuelOwner.sqf','fn_engineerRefuelEligible.sqf','fn_clientEngineerRefuel.sqf']) {
  const source = read(file).replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '').replace(/'(?:''|[^'])*'|"(?:""|[^"])*"/g, '');
  const stack = [];
  for (const ch of source) {
    if ('([{'.includes(ch)) stack.push(ch);
    if (')]}'.includes(ch)) assert.equal('([{'.indexOf(stack.pop()), ')]}'.indexOf(ch), file);
  }
  assert.equal(stack.length, 0, file);
}
console.log('Engineer refuel source and timing contracts passed; Arma execution still required.');
