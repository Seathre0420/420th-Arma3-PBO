// Delimiter/string smoke check, not an SQF compiler or an engine substitute.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const files = [
  ...fs.readdirSync(path.join(root,'Apex_framework.terrain/TGC/Functions/Damage')).filter(f => f.endsWith('.sqf')).map(f => 'Apex_framework.terrain/TGC/Functions/Damage/' + f),
  'Apex_framework.terrain/code/functions/fn_clientDamageModifier.sqf',
  'Apex_framework.terrain/code/functions/fn_clientEventHandleDamage.sqf',
  'Apex_framework.terrain/code/functions/fn_clientEventHit.sqf',
  'Apex_framework.terrain/code/functions/fn_clientEventFiredMan.sqf',
  'Apex_framework.terrain/code/functions/fn_clientInteractUnderwaterDemo.sqf',
  'Apex_framework.terrain/code/functions/fn_clientMenuActionContext.sqf',
  'Apex_framework.terrain/code/functions/fn_clientInteractUAVSelfDestruct.sqf',
  'Apex_framework.terrain/code/functions/fn_clientVehicleEventHandleDamage.sqf',
  'Apex_framework.terrain/code/functions/fn_clientVehicleEventHandlers.sqf',
  'Apex_framework.terrain/code/functions/fn_serverVehicleEventHandleDamage.sqf',
  'Apex_framework.terrain/code/functions/fn_spawnMenuManagedVehicleInit.sqf',
  'Apex_framework.terrain/code/functions/fn_vSetup.sqf',
  'Apex_framework.terrain/description.ext',
  'tests/friendly-fire/validate_engine.sqf'
];
for (const file of files) {
  const source = fs.readFileSync(path.join(root, file), 'utf8');
  const stack = [];
  let i = 0;
  while (i < source.length) {
    if (source.startsWith('//', i)) {
      const end = source.indexOf('\n', i);
      i = end < 0 ? source.length : end + 1;
    } else if (source.startsWith('/*', i)) {
      const end = source.indexOf('*/', i + 2);
      assert(end >= 0, file + ': unterminated comment');
      i = end + 2;
    } else if ('"\''.includes(source[i])) {
      const quote = source[i++];
      let closed = false;
      while (i < source.length) {
        if (source[i++] === quote) {
          if (source[i] === quote) i++;
          else { closed = true; break; }
        }
      }
      assert(closed, file + ': unterminated string');
    } else {
      const c = source[i++];
      if ('([{'.includes(c)) stack.push(c);
      if (')]}'.includes(c)) assert.equal(stack.pop(), '([{'[')]}'.indexOf(c)], file);
    }
  }
  assert.equal(stack.length, 0, file + ': unclosed delimiter');
}
console.log(`PASS: ${files.length} source files have balanced delimiters and strings.`);

const config = fs.readFileSync(path.join(root,'Apex_framework.terrain/description.ext'),'utf8');
for (const f of files.filter(f => f.includes('/Damage/') && !f.endsWith('/fn_setFriendlyName.sqf'))) {
  const name = path.basename(f,'.sqf').slice(3);
  assert(config.includes('class '+name+' '), 'Missing CfgFunctions registration: '+name);
}
for (const f of ['fn_clientEventHandleDamage.sqf','fn_clientVehicleEventHandleDamage.sqf']) {
  const src = fs.readFileSync(path.join(root,'Apex_framework.terrain/code/functions',f),'utf8');
  assert(src.indexOf('TGC_fnc_isFriendlyFire') < src.indexOf('params ['),f+': guard must precede damage side effects');
}
console.log('PASS: policy registration and callback guards.');
