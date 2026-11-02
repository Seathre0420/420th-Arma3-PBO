// Structural checks only. The README defines required Arma multiplayer checks.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const names = ['cargoMove', 'cargoPlaceClient', 'cargoPlacementClear', 'clientInteractCarry', 'clientInteractUnloadCargo',
  'clientMenuUnloadCargo', 'unloadCargoPlacementMode', 'clientEventDefaultAction',
  'clientEventDraw3D2', 'clientEventKeyDown3', 'clientInteractLoadCargo', 'clientInteractLoad', 'clientInteractRelease',
  'eventCargoLoaded', 'finishCargoChildUnload', 'remoteExec', 'virtualVehicleCargo',
  'getCargoVolume', 'getVirtualCargoVolume'];
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
for (const name of ['cargoMove', 'cargoPlaceClient', 'cargoPlacementClear']) {
  assert(config.includes(`class ${name} {file = "code\\functions\\fn_${name}.sqf";};`), `Unregistered function ${name}`);
}
assert(read('Apex_framework.terrain/code/config/security.hpp').includes('class QS_fnc_cargoMove {allowedTargets = 0; jip = 0;};'));
const worker = read('Apex_framework.terrain/code/functions/fn_cargoMove.sqf');
const confirmation = read('Apex_framework.terrain/code/functions/fn_cargoPlaceClient.sqf');
assert(confirmation.includes('if (local _cargo) then') && confirmation.includes('_request call QS_fnc_cargoMove'),
  'Owner-local requests must not depend on a network round trip');
assert(worker.includes("'REJECTED'"), 'Rejected protected requests must acknowledge failure');
// owner is server-only. Every client-originated cargo RPC must authenticate
// there, including a second Carry after the first one transferred locality.
const functionDir = path.join(root, 'Apex_framework.terrain/code/functions');
let clientRequests = 0;
for (const file of fs.readdirSync(functionDir).filter(file =>
  /^fn_client.*\.sqf$/.test(file) || ['fn_unloadCargoPlacementMode.sqf', 'fn_cargoPlaceClient.sqf'].includes(file))) {
  const source = fs.readFileSync(path.join(functionDir, file), 'utf8');
  for (const match of source.matchAll(/remoteExec(?:Call)?\s*\[\s*'QS_fnc_cargoMove'\s*,\s*([^,\]]+)/g)) {
    clientRequests++;
    assert.equal(match[1].trim(), '2', `${file}: cargo RPC bypasses server sender validation`);
  }
}
assert(clientRequests > 0, 'No client cargo RPCs checked');
const load = read('Apex_framework.terrain/code/functions/fn_clientInteractLoadCargo.sqf');
const protectedLoad = load.slice(load.indexOf("if ((_child getVariable ['QS_cargoMove_state',[]]) isNotEqualTo []) exitWith"), load.indexOf('if ([_parent,_child] call QS_fnc_setVehicleCargo)'));
assert(protectedLoad.includes('spawn QS_fnc_cargoPlaceClient'), 'Physical loading must await confirmation');
assert(!protectedLoad.includes("['QS_targetBoundingBox_placementMode',FALSE"), 'Rejected loading must retain carry controls');
// These helpers run inside cargoMove's dynamic scope. An unqualified assignment
// would replace its Object parameter with an Array after simulation was frozen.
for (const name of ['getCargoVolume', 'getVirtualCargoVolume']) {
  const source = read(`Apex_framework.terrain/code/functions/fn_${name}.sqf`);
  assert(/\bprivate\s+_cargo\s*=/.test(source), `${name} must isolate its cargo array`);
  assert(!/^\s*_cargo\s*=/m.test(source), `${name} must not overwrite the caller's cargo`);
}
assert(worker.indexOf('enableSimulationGlobal FALSE') < worker.indexOf('objNull setVehicleCargo'), 'Freeze must precede native release');
assert(worker.indexOf('enableSimulationGlobal FALSE') < worker.indexOf('detach _cargo'), 'Freeze must precede custom release');
for (const name of ['clientInteractUnloadCargo', 'clientMenuUnloadCargo', 'unloadCargoPlacementMode', 'clientEventDefaultAction', 'remoteExec']) {
  assert(read(`Apex_framework.terrain/code/functions/fn_${name}.sqf`).includes('QS_fnc_cargoMove'), `Unprotected entry point: ${name}`);
}
assert(!read('Apex_framework.terrain/code/functions/fn_clientEventDefaultAction.sqf').includes('[0,0,-1]'), 'Placement must not inject a downward velocity');
console.log('Cargo unload structure, registrations, and release ordering passed. Engine/multiplayer verification remains required.');
