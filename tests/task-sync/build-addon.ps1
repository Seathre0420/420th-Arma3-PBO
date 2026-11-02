param([switch]$VerifyOnly)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$source = Join-Path $repo '@apex/addons/apex_server'
$target = Join-Path $repo '@apex/addons/apex_server.pbo'
# Uncompressed PBO with an explicit virtual prefix; no game/server process needed.
$files = @(Get-ChildItem -LiteralPath $source -Recurse -File | Where-Object {$_.Extension -in '.sqf','.inc','.hpp','.cpp'} | Sort-Object FullName)
if (!$VerifyOnly) {
    $buffer = [IO.MemoryStream]::new()
    $writer = [IO.BinaryWriter]::new($buffer)
    function Write-Z([string]$value) { $writer.Write([Text.Encoding]::UTF8.GetBytes($value)); $writer.Write([byte]0) }
    Write-Z ''; $writer.Write([uint32]0x56657273); 1..4 | ForEach-Object {$writer.Write([uint32]0)}
    Write-Z 'prefix'; Write-Z 'apex_server'; Write-Z ''
    foreach ($file in $files) {
        Write-Z ($file.FullName.Substring($source.Length + 1))
        1..4 | ForEach-Object {$writer.Write([uint32]0)}
        $writer.Write([uint32]$file.Length)
    }
    Write-Z ''; 1..5 | ForEach-Object {$writer.Write([uint32]0)}
    foreach ($file in $files) {$writer.Write([IO.File]::ReadAllBytes($file.FullName))}
    $payload = $buffer.ToArray()
    $writer.Write([byte]0)
    $sha = [Security.Cryptography.SHA1]::Create()
    $writer.Write($sha.ComputeHash($payload)); $sha.Dispose()
    [IO.File]::WriteAllBytes($target,$buffer.ToArray()); $writer.Dispose()
}
$reader = [IO.BinaryReader]::new([IO.MemoryStream]::new([IO.File]::ReadAllBytes($target)))
function Read-Z { $bytes=[Collections.Generic.List[byte]]::new(); while (($b=$reader.ReadByte()) -ne 0) {$bytes.Add($b)}; [Text.Encoding]::UTF8.GetString($bytes.ToArray()) }
$name=Read-Z; $method=$reader.ReadUInt32(); 1..4 | ForEach-Object {$null=$reader.ReadUInt32()}
if ($name -ne '' -or $method -ne 0x56657273) {throw 'Missing PBO extension header'}
if ((Read-Z) -ne 'prefix' -or (Read-Z) -ne 'apex_server' -or (Read-Z) -ne '') {throw 'Wrong addon prefix'}
$entries=@()
while ($true) {
    $name=Read-Z; $header=@(1..5 | ForEach-Object {$reader.ReadUInt32()})
    if ($name -eq '') {break}
    if ($header[0] -ne 0) {throw 'Unexpected compression'}
    $entries+=,@($name,$header[4])
}
if ($entries.Count -ne $files.Count) {throw 'Entry count mismatch'}
foreach ($entry in $entries) {
    $actual=$reader.ReadBytes($entry[1]); $expected=[IO.File]::ReadAllBytes((Join-Path $source $entry[0]))
    if ([Convert]::ToBase64String($actual) -cne [Convert]::ToBase64String($expected)) {throw "Packed source mismatch: $($entry[0])"}
}
$reader.Dispose()
Write-Output "PASS: $($entries.Count) packed entries match source; prefix apex_server"