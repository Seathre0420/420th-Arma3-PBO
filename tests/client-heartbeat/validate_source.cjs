const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const functions = path.resolve(__dirname, '../../Apex_framework.terrain/code/functions');
const read = name => fs.readFileSync(path.join(functions, `fn_${name}.sqf`), 'utf8');
const heartbeat = read('clientHeartbeat');
const core = read('clientCore');
const init = read('initPlayerLocal');

for (const name of ['clientHeartbeat', 'clientCore', 'initPlayerLocal']) {
  const tokens = read(name).replace(/\/\*[\s\S]*?\*\/|\/\/[^\r\n]*|'(?:''|[^'])*'|"(?:""|[^"])*"/g, '');
  const stack = [];
  for (const char of tokens) {
    if ('([{'.includes(char)) stack.push(char);
    if (')]}'.includes(char)) {
      assert.equal(stack.pop(), {')': '(', ']': '[', '}': '{'}[char], `Unbalanced ${name}`);
    }
  }
  assert.equal(stack.length, 0, `Unclosed delimiter in ${name}`);
}

assert(init.includes("['QS_client_heartbeatFailure',[],FALSE]"), 'Failure state must start client-local');
assert(heartbeat.includes("getVariable ['QS_client_heartbeatFailure',[]]"), 'Existing clients need a default');
assert(heartbeat.includes("getVariable ['QS_client_heartbeat',-1]"), 'Missing heartbeat must enter grace safely');
assert(heartbeat.includes('abs (_timeNow - _heartbeat) <= 60'), 'Preserve both tolerance boundaries');
assert(heartbeat.includes('_timeNow <= 120'), 'Preserve startup grace');
assert(heartbeat.includes('(diag_tickTime - (_failure # 0)) < 60'), 'Confirmation needs real elapsed grace');
assert.equal((core.match(/\[_timeNow\] call _fn_refreshHeartbeat;/g) || []).length, 2, 'Both heartbeat writes must reset pending failure');
assert.equal((core.match(/setVariable \['QS_client_heartbeat',/g) || []).length, 1, 'Heartbeat writes must share the recovery path');

const confirmation = heartbeat.indexOf("[_failure # 0,_failure # 1,TRUE]");
const report = heartbeat.indexOf("remoteExec ['QS_fnc_remoteExec',2,FALSE]");
const counter = heartbeat.indexOf("setVariable ['QS_heartAttacks',_heartAttacks + 1,TRUE]");
const sleep = heartbeat.indexOf('uiSleep');
assert(confirmation > 0 && confirmation < report && counter < sleep, 'Commit confirmation and counter before reporting or yielding');
assert(heartbeat.includes('if ((_failure # 2) ||'), 'Confirmed failures must suppress duplicates');
assert(heartbeat.includes('_shouldEnd = _heartAttacks < 3'), 'Keep existing kick limit');
assert(heartbeat.includes("endMission 'QS_RD_end_2'"), 'Retain debriefing');
for (const field of ['missionTime=', 'serverTime=', 'heartbeat=', 'age=', 'graceElapsed=', 'fps=', 'activeScripts=', 'sqfScripts=', 'sqsScripts=', 'fsmScripts=', 'weapon=', 'magazine=', 'inShootingRange=']) {
  assert(heartbeat.includes(field) && core.includes(field), `Missing diagnostic field ${field}`);
}
console.log('Client heartbeat structure and lifecycle checks passed. Run the engine harness for SQF behavior.');
