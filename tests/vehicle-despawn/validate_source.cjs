// Run with node tests/vehicle-despawn/validate_source.cjs. No dependencies.
const fs = require('node:fs');
const cp = require('node:child_process');
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
// Prove every instrumented existing file is exactly its original source with
// only deleteVehicle operands wrapped. This catches accidental gameplay edits.
let sites = 0;
for (const file of fs.readdirSync(require('node:path').join(root, 'Apex_framework.terrain/code/functions'))) {
  const p = `Apex_framework.terrain/code/functions/${file}`;
  let s = read(p); balanced(s);
  if (file.startsWith('fn_vehicleDespawn')) continue;
  if (!s.includes("['CONTEXT',")) continue;
  const pattern = /\(\['CONTEXT',([\s\S]*?),'(?:ABANDONED|SPAWN_PROTECTION|DISCONNECT|MANUAL|UAV_CLEANUP|WRECK_CLEANUP|GARBAGE_COLLECTION|MISSION_CLEANUP|REPLACED|REMOVED)','fn_[^']+',(?:\[\]|\['ownerDistance',[^\n]*?\]|\['instruction',[^\n]*?\])\] call QS_fnc_vehicleDespawnLog\)/g;
  s = s.replace(pattern, (_, operand) => { sites++; return operand; });
  s = s.replace(/^\t\['(?:PACKED|UNPACKED)',[^\n]+ call QS_fnc_vehicleDespawnLog;\r?\n/gm, '');
  const original = cp.execFileSync('git', ['show', `HEAD:${p}`], {cwd: root, encoding: 'utf8'});
  const normalize = text => text.replace(/\r\n/g, '\n').replace(/[\t ]+$/gm, '');
  assert.equal(normalize(s), normalize(original), p);
}
assert(sites > 100, 'Missing broad removal-site coverage');
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
console.log(`PASS: SQF structure, ${sites} behavior-preserving annotations, observer registration, report isolation and state expiry. Multiplayer testing required.`);
