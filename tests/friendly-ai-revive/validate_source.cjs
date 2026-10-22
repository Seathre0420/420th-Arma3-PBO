// Delimiter/string smoke check, not an SQF compiler or an engine substitute.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const files = [
  'TGC/Functions/Damage/fn_friendlyAICasualty.sqf',
  'TGC/Functions/Damage/fn_addFriendlyAIHandlers.sqf',
  'TGC/Functions/Damage/fn_initFriendlyAIProtection.sqf',
  'code/functions/fn_clientInteractRevive.sqf',
  'code/functions/fn_rcAIRevive.sqf',
  'code/functions/fn_remoteExec.sqf',
  'description.ext'
].map(f => 'Apex_framework.terrain/' + f);
files.push('tests/friendly-ai-revive/validate_engine.sqf');
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
