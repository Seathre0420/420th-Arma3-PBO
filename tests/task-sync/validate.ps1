$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$paths = @(
    '@apex/addons/apex_server/BIS/fn_setTask.sqf',
    '@apex/addons/apex_server/BIS/fn_deleteTask.sqf',
    'Apex_framework.terrain/code/functions/fn_taskSyncClient.sqf',
    'Apex_framework.terrain/code/functions/fn_taskSyncServer.sqf',
    'Apex_framework.terrain/code/functions/fn_taskSyncRequest.sqf'
)
foreach ($path in $paths) {
    $text=[IO.File]::ReadAllText((Join-Path $repo $path))
    $tokens=[regex]::Replace($text,'(?s)/\*.*?\*/|(?m)//[^\r\n]*|''(?:''''|[^''])*''|"(?:""|[^"])*"','')
    $stack=[Collections.Generic.Stack[char]]::new()
    foreach ($char in $tokens.ToCharArray()) {
        if ('([{'.Contains([string]$char)) {$stack.Push($char)}
        if (')]}'.Contains([string]$char)) {
            if ($stack.Count -eq 0) {throw "Unmatched delimiter in $path"}
            $open=$stack.Pop()
            if ('([{'.IndexOf($open) -ne ')]}'.IndexOf($char)) {throw "Mismatched delimiter in $path"}
        }
    }
    if ($stack.Count) {throw "Unclosed delimiter in $path"}
}
function Require([string]$path,[string]$needle) {
    if (![IO.File]::ReadAllText((Join-Path $repo $path)).Contains($needle)) {throw "Missing integration in ${path}: $needle"}
}
Require $paths[1] '_init = _this param [3,true,[true]]'
Require $paths[0] "['SET',_id,_snapshot] call QS_fnc_taskSyncServer"
Require $paths[2] 'remoteExecutedOwner isNotEqualTo 2'
Require $paths[2] '_revision >= (_seen getOrDefault [_id,-1])'
Require $paths[2] 'QS_taskSync_handoff'
Require $paths[3] 'QS_TASK_SNAPSHOT'
Require $paths[4] '[''REQUEST''] call QS_fnc_taskSyncServer'
Require 'Apex_framework.terrain/code/config/security.hpp' 'class QS_fnc_taskSyncRequest {allowedTargets = 2;};'
Require 'Apex_framework.terrain/description.ext' 'class taskSyncClient'
Require 'Apex_framework.terrain/description.ext' 'class taskSyncServer'
Require 'Apex_framework.terrain/code/config/security.hpp' 'class QS_fnc_taskSyncClient {allowedTargets = 1; jip = 1;}'
foreach ($file in 'fn_initPlayerLocal.sqf','fn_clientEventRespawn.sqf','fn_clientCore.sqf') {
    Require "Apex_framework.terrain/code/functions/$file" "['REQUEST'] remoteExecCall ['QS_fnc_taskSyncRequest',2]"
}
& (Join-Path $PSScriptRoot 'build-addon.ps1') -VerifyOnly
Write-Output 'PASS: task integration and delimiter checks (static only)'
