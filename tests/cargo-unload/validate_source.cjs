// Structural checks only. The README defines required Arma multiplayer checks.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const names = ['cargoMove', 'cargoPlacementClear', 'clientInteractUnloadCargo',
  'clientMenuUnloadCargo', 'unloadCargoPlacementMode', 'clientEventDefaultAction',
  'clientEventDraw3D2', 'clientInteractLoadCargo', 'clientInteractRelease',
  'eventCargoLoaded', 'finishCargoChildUnload', 'remoteExec', 'virtualVehicleCargo'];
for (const name of names) {
  const source = read(`Apex_framework.terrain/code/functions/fn_${name}.sqf`);
  const stack = [];
  for (let i = 0; i < source.length; i++) {
    if (source.startsWith('//', i)) {
      const end = source.indexOf('\n', i); i = end < 0 ? source.length : end;
    } else if (source.startsWith('/*', i)) {
      const end = source.indexOf('*/', i + 2);
      assert(end >= 0, `Unclosed comment in ${name}`); i = end + 1;
    } else if (`'"`.includes(source[i])) {
      const quote = source[i]; let closed = false;
      while (++i < source.length) if (source[i] === quote) {
        if (source[i + 1] === quote) i++;
        else { closed = true; break; }
      }
      assert(closed, `Unclosed string in ${name}`);
    } else if ('([{'.includes(source[i])) stack.push(source[i]);
    else if (')]}'.includes(source[i])) assert.equal(stack.pop(), {')':'(', ']':'[', '}':'{'}[source[i]], name);
  }
  assert.equal(stack.length, 0, `Unclosed delimiter in ${name}`);
}
const config = read('Apex_framework.terrain/description.ext');
for (const name of ['cargoMove', 'cargoPlacementClear']) {
  assert(config.includes(`class ${name} {file = "code\\functions\\fn_${name}.sqf";};`), `Unregistered function ${name}`);
}
assert(read('Apex_framework.terrain/code/config/security.hpp').includes('class QS_fnc_cargoMove {allowedTargets = 0; jip = 0;};'));
const worker = read('Apex_framework.terrain/code/functions/fn_cargoMove.sqf');
assert(worker.indexOf('enableSimulationGlobal FALSE') < worker.indexOf('objNull setVehicleCargo'), 'Freeze must precede native release');
assert(worker.indexOf('enableSimulationGlobal FALSE') < worker.indexOf('detach _cargo'), 'Freeze must precede custom release');
for (const name of ['clientInteractUnloadCargo', 'clientMenuUnloadCargo', 'unloadCargoPlacementMode', 'clientEventDefaultAction', 'remoteExec']) {
  assert(read(`Apex_framework.terrain/code/functions/fn_${name}.sqf`).includes('QS_fnc_cargoMove'), `Unprotected entry point: ${name}`);
}
assert(!read('Apex_framework.terrain/code/functions/fn_clientEventDefaultAction.sqf').includes('[0,0,-1]'), 'Placement must not inject a downward velocity');
console.log('Cargo unload structure, registrations, and release ordering passed. Engine/multiplayer verification remains required.');
