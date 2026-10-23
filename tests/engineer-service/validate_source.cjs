// Static integration checks only. Run validate_engine.sqf for actual SQF/network behavior.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../../Apex_framework.terrain');
const read = n => fs.readFileSync(path.join(root, 'code/functions', `fn_${n}.sqf`), 'utf8');
const names = ['clientEngineerService','engineerServiceServer','engineerServiceOwner','engineerServiceResponse','engineerServiceReply','engineerServiceWork','engineerServiceReason'];
const sources = Object.fromEntries(names.map(n => [n,read(n)]));
const config = fs.readFileSync(path.join(root, 'description.ext'), 'utf8');
const security = fs.readFileSync(path.join(root, 'code/config/security.hpp'), 'utf8');
for (const name of names) assert(config.includes(`class ${name} {file = "code\\functions\\fn_${name}.sqf";};`), name);
for (const name of ['engineerServiceServer','engineerServiceOwner','engineerServiceResponse']) assert(security.includes(`class QS_fnc_${name} `), name);
assert(!/QS_fnc_engineer(?:Repair|Refuel)Owner/.test(security), 'Remove obsolete RPC entry points');
assert(!/engineer(?:Repair|Refuel)_(?:request|status)/.test(Object.values(sources).join('\n')), 'No independently replicated request tokens');
const owner = sources.engineerServiceOwner, client = sources.clientEngineerService, work = sources.engineerServiceWork;
const server = sources.engineerServiceServer;
assert(server.includes('remoteExecutedOwner != owner _unit'), 'Server authenticates control sender');
assert(server.includes('!isServer') && security.includes('class QS_fnc_engineerServiceServer {allowedTargets = 2;'), 'Ownership resolver only executes on server');
assert(owner.includes('remoteExecutedOwner != 2'), 'Worker accepts only server-relayed controls');
assert(server.includes('remoteExecutedOwner != _target'), 'Server authenticates worker replies');
assert(server.includes('private _target = owner _vehicle;') && server.includes('if (_target >= 2)'), 'Never route to broadcast target zero');
assert(client.includes('private _target = 2;'), 'Client talks to server, not a client-side owner result');
for (const [name,source] of Object.entries(sources)) {
  if (name !== 'engineerServiceServer') assert(!/\bowner\s+_\w+/.test(source.replace(/\/\/[^\n]*/g, '')), `${name}: owner is server-only`);
}
assert(sources.engineerServiceReply.includes("remoteExecCall ['QS_fnc_engineerServiceServer',2]"), 'Worker replies through authenticated server route');
assert(sources.engineerServiceResponse.includes('remoteExecutedOwner != _expectedOwner'), 'Authenticate reply sender');
assert(sources.engineerServiceResponse.includes('_token != _expectedToken'), 'Ignore stale session replies');
assert(owner.includes("if (_op == 'ready') then {_session set [6,'running'];}"));
assert(work.indexOf("if ((_session # 6) != 'running') exitWith {};") < work.indexOf('setFuel'), 'No mutation before ready');
assert(work.includes("if (_now > (_session # 5))"), 'Owner lease expiration');
assert(client.includes("['cancel',_vehicle,_unit,_token,_mode] remoteExecCall"), 'Explicit cancellation');
assert(work.includes('deleteAt _key') && work.includes('removeEventHandler'), 'Terminal cleanup');
assert(work.indexOf('private _remaining =') < work.indexOf('while {!_done}'), 'Progress state must outlive the atomic block');
const repairBranch = work.split("if (_mode == 'refuel') then {")[1].split('} else {')[1];
assert(!/setFuel|setVehicleAmmo/.test(repairBranch), 'Repair must not refuel or rearm');
for (const [name, source] of Object.entries(sources)) {
  const tokens = source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '').replace(/'(?:''|[^'])*'|"(?:""|[^"])*"/g, '');
  const stack = [];
  for (const c of tokens) {
    if ('([{'.includes(c)) stack.push(c);
    if (')]}'.includes(c)) assert.equal('([{'.indexOf(stack.pop()), ')]}'.indexOf(c), name);
  }
  assert.equal(stack.length,0,name);
}
for (const [name,mode] of [['Repair','repair'],['Refuel','refuel']]) {
  assert(read(`clientEngineer${name}`).includes(`[_vehicle,'${mode}'] call QS_fnc_clientEngineerService`));
  assert(read(`engineer${name}Eligible`).includes(`[_unit,_vehicle,'${mode}'] call QS_fnc_engineerServiceReason`));
}
console.log('Engineer service integration checks passed. These do not execute SQF or validate multiplayer delivery.');
