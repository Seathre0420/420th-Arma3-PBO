const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const functions = path.join(root, 'Apex_framework.terrain/code/functions');
const config = fs.readFileSync(path.join(root, 'Apex_framework.terrain/description.ext'), 'utf8');
const security = fs.readFileSync(path.join(root, 'Apex_framework.terrain/code/config/security.hpp'), 'utf8');
const names = ['vehicleAccessSeats','vehicleAccessApply','vehicleAccessServer','vehicleAccessBoard','vehicleAccessExternalLock','vehicleAccessNear'];
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
// Regression: unlisted action titles cause the anti-hack handler to remove ALL
// player actions, making an otherwise correct owner bypass inaccessible.
const client = fs.readFileSync(path.join(functions, 'fn_clientVehicleAccess.sqf'), 'utf8');
const whitelist = fs.readFileSync(path.join(root, 'Apex_framework.terrain/code/config/QS_data_actions.sqf'), 'utf8');
const titles = [...new Set(client.match(/'(?:Take Ownership|Vehicle Access|Enter Owned Vehicle[^']*)'/g))];
assert.equal(titles.length, 7, 'Ownership/menu action and all five role choices must exist');
for (const title of titles) assert(whitelist.includes(title), `Anti-hack would remove owner action ${title}`);
const server = fs.readFileSync(path.join(functions, 'fn_vehicleAccessServer.sqf'), 'utf8');
const board = fs.readFileSync(path.join(functions, 'fn_vehicleAccessBoard.sqf'), 'utf8');
assert(server.includes('[_unit,_vehicle,_group] remoteExecCall'), 'Server must preserve requested role');
assert(board.includes('private _roles = [_requestedRole] select'), 'Boarding must not silently choose another role');
for (const source of [client, server, board]) {
  assert(source.includes('call QS_fnc_vehicleAccessNear'), 'UI, server and boarding must share proximity rules');
  assert(!/distance (?:_vehicle|_v|cursorObject)\s*(?:<=|>)\s*3/.test(source), 'Model-origin radius would strand owners at large vehicle doors');
}
console.log('Vehicle access registrations, source structure, owner whitelist and seat request regression checks passed. Dedicated multiplayer checks remain required.');
