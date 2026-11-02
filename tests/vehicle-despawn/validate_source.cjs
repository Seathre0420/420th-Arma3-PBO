// Run with node tests/vehicle-despawn/validate_source.cjs. No dependencies.
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const root = require('node:path').resolve(__dirname, '../..');
const read = p => fs.readFileSync(require('node:path').join(root, p), 'utf8');
function balanced(s) {
  const stack = [];
  for (let i = 0; i < s.length; i++) {
    if (s.startsWith('//', i)) { const end = s.indexOf('\n', i); i = end < 0 ? s.length : end; }
    else if (s.startsWith('/*', i)) { const end = s.indexOf('*/', i + 2); assert(end >= 0); i = end + 1; }
    else if ('\'"'.includes(s[i])) {
      const q = s[i]; let closed = false;
      while (++i < s.length) if (s[i] === q) { if (s[i + 1] === q) i++; else { closed = true; break; } }
      assert(closed, 'Unterminated string');
    } else if ('([{'.includes(s[i])) stack.push(s[i]);
    else if (')]}'.includes(s[i])) assert.equal(stack.pop(), '([{'[')]}'.indexOf(s[i])]);
  }
  assert.equal(stack.length, 0);
}
// Validate coverage independently of Git history, including after commits.
let sites = 0;
for (const file of fs.readdirSync(require('node:path').join(root, 'Apex_framework.terrain/code/functions'))) {
  const s = read('Apex_framework.terrain/code/functions/' + file);
  balanced(s);
  sites += (s.match(/\['CONTEXT',/g) || []).length;
}
assert(sites > 100, 'Missing broad removal-site coverage');
const core = read('Apex_framework.terrain/code/functions/fn_core.sqf');
const begin = core.indexOf("\t\t\tif ((missionNamespace getVariable 'QS_garbageCollector') isNotEqualTo []) then {");
const finish = core.indexOf('\t\t\t\t} count _QS_garbageCollector;', begin);
assert(begin >= 0 && finish > begin);
const cleanup = core.slice(begin, finish + '\t\t\t\t} count _QS_garbageCollector;'.length);
assert.equal((cleanup.match(/_despawnCleanupDetails pushBack/g) || []).length, 2);
const deletionPass = cleanup.slice(cleanup.indexOf('if (_QS_garbageCollector isNotEqualTo []) then {'));
assert(!/_QS_instructions|_QS_timeDelete/.test(deletionPass), 'Deletion pass must use captured metadata');
assert.equal((deletionPass.match(/,_despawnCleanupDetail\] call QS_fnc_vehicleDespawnLog/g) || []).length, 3);
assert(deletionPass.indexOf('_despawnCleanupIndex = _despawnCleanupIndex + 1;') < deletionPass.indexOf('if (!isNull _x)'), 'Null entries must also advance metadata');
// Exercise metadata transport from the actual SQF expressions with distinct
// queue entries, successful recycling, null entries and a fresh subsequent pass.
// This evaluates only the array/index operations, not Arma deletion semantics.
const vm = require('node:vm');
const captureLines = [...cleanup.matchAll(/_despawnCleanupDetails pushBack (\[[^\n;]+\]);/g)].map(m => m[1]);
assert.equal(captureLines[0], captureLines[1]);
const lookup = deletionPass.match(/private _despawnCleanupDetail = ([^;]+);/)[1];
const advance = deletionPass.match(/_despawnCleanupIndex = (_despawnCleanupIndex \+ 1);/)[1];
function transport(entries) {
  const state = {_despawnCleanupDetails: [], _despawnCleanupIndex: 0};
  const queued = [];
  for (const entry of entries) {
    if (entry.recycled) continue;
    Object.assign(state, {_QS_instructions: entry.instruction, _QS_timeDelete: entry.deadline});
    state._despawnCleanupDetails.push(vm.runInNewContext(captureLines[0], state));
    queued.push(entry);
  }
  const records = [];
  for (const entry of queued) {
    const detail = vm.runInNewContext(lookup.replace(' # ', '[') + ']', state);
    state._despawnCleanupIndex = vm.runInNewContext(advance, state);
    if (!entry.gone) records.push([entry.id, Array.from(detail)]);
  }
  return records;
}
assert.deepEqual(transport([
  {id: 'A', instruction: 'NOW_FORCED', deadline: 0},
  {id: 'recycled', instruction: 'NOW_DISCREET', deadline: 10, recycled: true},
  {id: 'gone', instruction: 'DELAYED_FORCED', deadline: 20, gone: true},
  {id: 'B', instruction: 'DELAYED_DISCREET', deadline: 30}
]), [
  ['A', ['instruction', 'NOW_FORCED', 'deadline', 0]],
  ['B', ['instruction', 'DELAYED_DISCREET', 'deadline', 30]]
]);
assert.deepEqual(transport([{id: 'C', instruction: 'NOW_DISCREET', deadline: 40}]),
  [['C', ['instruction', 'NOW_DISCREET', 'deadline', 40]]]);
assert.deepEqual(transport([{recycled: true}]), []);
// Pin existing cleanup behavior, excluding diagnostics. Independent of HEAD.
const gameplay = cleanup
  .replace(/\(\['CONTEXT',([^,]+),'GARBAGE_COLLECTION','[^']+',(?:\['instruction',[^\n]+?\]|_despawnCleanupDetail)\] call QS_fnc_vehicleDespawnLog\)/g, '$1')
  .replace(/^.*(?:private _despawnCleanup|_despawnCleanupDetails pushBack|_despawnCleanupIndex = _despawnCleanupIndex \+ 1;).*\r?\n/gm, '')
  .replace(/\r\n/g, '\n').replace(/[\t ]+$/gm, '');
assert.equal(crypto.createHash('sha256').update(gameplay).digest('hex'), '05e4317033ac7e308b50bff5ca1f6e168617b5e645b70a3f7c306e0010aee3b0', 'Cleanup behavior changed outside diagnostics');
const logger = read('Apex_framework.terrain/code/functions/fn_vehicleDespawnLog.sqf');
const init = read('Apex_framework.terrain/code/functions/fn_vehicleDespawnLogInit.sqf');
const report = read('Apex_framework.terrain/code/functions/fn_vehicleDespawnReport.sqf');
assert(init.includes("'EntityDeleted'"));
assert(init.includes('if (!isServer) exitWith {}'));
assert(init.includes('QS_despawn_initialized'));
assert(logger.includes('if (isNull _object) then'), 'Must verify actual deletion');
assert(logger.includes('_pending deleteAt _x'), 'Pending events must retire');
assert(logger.includes('_reports deleteAt _x'), 'Unmatched provenance must expire');
assert(report.includes('remoteExecutedOwner > 2'));
assert(report.includes('count _reports < 4096'));
assert(!report.includes('diag_log'), 'Reports cannot fabricate deletion records');
assert(!/\b(deleteVehicle|setOwner|setDamage|setPos|hideObjectGlobal)\b/.test(logger.replace(/\/\*[\s\S]*?\*\//g, '')), 'Logger must be read-only');
assert(!/allMissionObjects|allSimpleObjects/.test(logger + init));
assert(read('Apex_framework.terrain/code/config/security.hpp').includes('class QS_fnc_vehicleDespawnReport {allowedTargets = 2; jip = 0;};'));
console.log(`PASS: SQF structure, ${sites} removal annotations, preserved cleanup behavior, observer registration, report isolation and state expiry. Multiplayer testing required.`);
