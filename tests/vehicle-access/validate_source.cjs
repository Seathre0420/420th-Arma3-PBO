const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const functions = path.join(root, 'Apex_framework.terrain/code/functions');
const config = fs.readFileSync(path.join(root, 'Apex_framework.terrain/description.ext'), 'utf8');
const security = fs.readFileSync(path.join(root, 'Apex_framework.terrain/code/config/security.hpp'), 'utf8');
const names = ['vehicleAccessSeats','vehicleAccessApply','vehicleAccessServer','vehicleAccessBoard','vehicleAccessExternalLock'];
const changed = ['clientVehicleAccess','clientInGameUIAction','clientInteractGetIn','clientInteractMH9Stealth','clientEventGetOutMan','clientEventRespawn','initPlayerLocal','vSetup','remoteExecCmd','clientMenuActionContext'];
for (const name of names) {
  assert(config.includes(`class ${name} {file = "code\\functions\\fn_${name}.sqf";};`), `Missing function registration: ${name}`);
}
for (const name of ['vehicleAccessApply','vehicleAccessServer','vehicleAccessBoard']) {
  assert(security.includes(`class QS_fnc_${name} `), `Missing RPC registration: ${name}`);
}
// Lexical balance, ignoring SQF strings (including doubled quote escapes) and comments.
for (const name of [...names, ...changed]) {
  const source = fs.readFileSync(path.join(functions, `fn_${name}.sqf`), 'utf8');
  const tokens = source.replace(/\/\*[\s\S]*?\*\/|\/\/[^\r\n]*|'(?:''|[^'])*'|"(?:""|[^"])*"/g, '');
  const stack = [];
  for (const c of tokens) {
    if ('([{'.includes(c)) stack.push(c);
    if (')]}'.includes(c)) assert.equal(stack.pop(), {')':'(',']':'[','}':'{'}[c], `Unbalanced ${name}`);
  }
  assert.equal(stack.length, 0, `Unclosed delimiter: ${name}`);
}
console.log('Vehicle access registrations and source structure passed. Dedicated multiplayer checks remain required.');
