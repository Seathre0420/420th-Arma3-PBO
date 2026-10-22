// Read-only structural checks. Run from the repository root with Node.js.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const base = 'Apex_framework.terrain/code/functions/';
const read = name => fs.readFileSync(base + name + '.sqf', 'utf8');
const files = ['fn_roles','fn_remoteExec','fn_initPlayerServer','fn_clientCore','fn_core','fn_casRespawn','fn_eventEntityRespawned'];
// Strip SQF strings (including doubled quotes) and comments before balancing.
for (const name of files) {
 const s = read(name).replace(/\/\*[\s\S]*?\*\//g,'').replace(/\/\/[^\r\n]*/g,'').replace(/'([^']|'')*'|"([^"]|"")*"/g,'');
 const stack=[];
 for(const c of s) {
  if('([{'.includes(c)) stack.push(c);
  if(')]}'.includes(c)) assert.equal(stack.pop(),{')':'(',']':'[','}':'{'}[c],name+' delimiters');
 }
 assert.equal(stack.length,0,name+' unclosed delimiter');
}
const roles=read('fn_roles'), rx=read('fn_remoteExec'), login=read('fn_initPlayerServer');
assert(rx.indexOf('_case isEqualTo 127') > rx.indexOf('if (_case < 130) exitWith {'));
assert(rx.includes('_case in [16,121]') && rx.includes('_rxID isNotEqualTo 2'));
assert(rx.includes('_target isNotEqualTo player') && rx.includes('QS_loginSession'));
assert(roles.includes('(_accepted # 3) >= _revision'));
assert(roles.includes("_reason isEqualTo 'initial'"));
assert(roles.includes("['_expected',[]]") && roles.includes('isNotEqualTo _expected'));
assert.equal((roles.match(/\[121,\[121,/g)||[]).length,(roles.match(/remoteExec \['QS_fnc_remoteExec',_(?:unit|queuedUnit),FALSE\]/g)||[]).length-1); // one case-16 publisher
assert(login.indexOf('QS_loginStarted') < login.indexOf("['HANDLE',['HANDLE_CONNECT'"));
assert(login.includes('QS_loginReply') && login.includes('QS_roleState'));
for(const name of ['fn_core','fn_casRespawn']) {
 assert(read(name).includes("isEqualTo 'pilot_plane'"));
 assert(read(name).includes("'cas',") && read(name).includes('QS_roleState'));
}
assert(read('fn_casRespawn').includes('QS_casAssignment'));
assert(read('fn_eventEntityRespawned').includes("['PUBLISH',_newEntity,'respawn']"));
assert(roles.includes("params ['_role','_state']") && roles.includes("['QS_roleAccepted',[]]) isNotEqualTo _state"));
console.log('Role synchronization source checks passed (not an SQF compiler or engine test).');
