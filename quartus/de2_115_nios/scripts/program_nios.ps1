param([string]$QuartusRoot='C:/altera_lite/25.1std/quartus')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lab_tools.ps1')
$log=Join-Path $root 'build_quartus.log'
if(!(Test-Path -LiteralPath $log) -or (Select-String -LiteralPath $log -Pattern 'Failed to acquire license|Simulation-Only|Critical Warning|Error \(' -Quiet)){
 throw 'Nios build is not cleared for hardware. Obtain no-cost IP-NIOSVC license and run build_all.cmd first.'
}
$sof=Join-Path $root 'output_files/de2_115_nios.sof'
$manifest=Import-Csv -LiteralPath (Join-Path $root 'SHA256SUMS.csv')
$expected=@($manifest | Where-Object path -eq 'output_files/de2_115_nios.sof')
if($expected.Count -ne 1 -or (Get-FileHash -LiteralPath $sof).Hash -ne $expected[0].sha256){throw 'SOF hash mismatch; update validated package after rebuild'}
New-Item -ItemType Directory -Path (Join-Path $root 'build/lab') -Force | Out-Null
$scan=Invoke-LabNative (Join-Path $QuartusRoot 'bin64/jtagconfig.exe') @() (Join-Path $root 'build/lab/jtag_scan.log')
$targets=@(Get-De2Target $scan.Lines)
if($scan.Code -ne 0 -or $targets.Count -ne 1){throw 'Need exactly one DE2-115/EP4CE115 JTAG target'}
$stage=Join-Path ([IO.Path]::GetTempPath()) ('nios_pgm_'+[Guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $stage | Out-Null
$staged=Join-Path $stage 'nios.sof';Copy-Item -LiteralPath $sof -Destination $staged
$target=$targets[0]
$result=Invoke-LabNative (Join-Path $QuartusRoot 'bin64/quartus_pgm.exe') @('-c',"$($target.Cable)",'-m','JTAG','-o',"p;$staged@$($target.Device)") (Join-Path $root 'build/lab/program.log')
$result.Lines | Write-Output
if($result.Code -ne 0 -or !($result.Lines -match 'Configuration succeeded')){throw 'Programming not confirmed'}
'PASS Nios hardware and embedded C firmware programmed. SW0=1 for JTAG mode; SW0=0 for RS232. Press KEY0 after changing SW0.'
