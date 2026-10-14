param([string]$QuartusRoot='C:/altera_lite/25.1std/quartus',[string]$LicenseFile)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Path (Join-Path $root 'build') -Force | Out-Null
if($LicenseFile){
 if(!(Test-Path -LiteralPath $LicenseFile)){throw 'License file was not found'}
 $env:LM_LICENSE_FILE=(Resolve-Path -LiteralPath $LicenseFile).Path
}
function Run-Checked {
 param([string]$Exe,[string[]]$Arguments,[string]$Log)
 $ErrorActionPreference='Continue'
 $output=@(& $Exe @Arguments 2>&1 | ForEach-Object {"$_"})
 $code=$LASTEXITCODE
 $output | Set-Content -LiteralPath $Log -Encoding UTF8
 if($code -ne 0){$output | Select-Object -Last 25 | Write-Output;throw "Tool failed ($code): $Exe; see $Log"}
}
Run-Checked 'python' @((Join-Path $PSScriptRoot 'build_firmware.py')) (Join-Path $root 'build/firmware_build.log')
Run-Checked 'python' @((Join-Path $PSScriptRoot 'test_firmware.py')) (Join-Path $root 'build/firmware_test.log')
$stage=Join-Path ([IO.Path]::GetTempPath()) ('n6_'+[Guid]::NewGuid().ToString('N').Substring(0,8))
New-Item -ItemType Directory -Path $stage | Out-Null
foreach($dir in @('core','rtl','scripts')){Copy-Item -LiteralPath (Join-Path $root $dir) -Destination $stage -Recurse}
foreach($file in @('nios_uart_peripheral_hw.tcl','firmware.mif','create_project.tcl','de2_115_nios.sdc')){Copy-Item -LiteralPath (Join-Path $root $file) -Destination $stage}
Push-Location $stage
try {
 Run-Checked (Join-Path $QuartusRoot 'sopc_builder/bin/qsys-script.exe') @('--script=scripts/create_system.tcl','--search-path=./**/*,$') 'create_system.log'
 Run-Checked (Join-Path $QuartusRoot 'sopc_builder/bin/qsys-generate.exe') @('nios_system.qsys','--synthesis=VERILOG','--search-path=./**/*,$') 'generate.log'
 Run-Checked (Join-Path $QuartusRoot 'bin64/quartus_sh.exe') @('-t','create_project.tcl') 'create_project.log'
 Run-Checked (Join-Path $QuartusRoot 'bin64/quartus_sh.exe') @('--flow','compile','de2_115_nios') 'build_quartus.log'
 if(Select-String -LiteralPath 'build_quartus.log' -Pattern 'Critical Warning|Error \(|Failed to acquire license|Simulation-Only' -Quiet){
  Copy-Item -LiteralPath 'build_quartus.log' -Destination (Join-Path $root 'build/build_not_ready.log') -Force
  throw 'Build is not cleared for hardware: review license/errors in build/build_not_ready.log. Acquire the no-cost IP-NIOSVC license and rebuild.'
 }
 if(!(Test-Path -LiteralPath 'output_files/de2_115_nios.sof')){throw 'SOF missing'}
 if(Select-String -LiteralPath 'output_files/de2_115_nios.sta.summary' -Pattern '^Slack\s*:\s*-' -Quiet){throw 'Timing has negative slack; do not program'}
 foreach($dir in @('nios_system','output_files')){Copy-Item -LiteralPath (Join-Path $stage $dir) -Destination $root -Recurse -Force}
 foreach($file in @('nios_system.qsys','nios_system.sopcinfo','de2_115_nios.qpf','de2_115_nios.qsf','build_quartus.log','create_system.log','generate.log')){
  if(Test-Path -LiteralPath $file){Copy-Item -LiteralPath $file -Destination $root -Force}
 }
 [PSCustomObject]@{hardware_ready=$true;cpu='Nios V/c 4.1.0';firmware_embedded=$true;
  validation='Firmware/RTL tests passed; licensed Quartus compile and timing passed';
  board_test='Not performed';time=(Get-Date -Format o)} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'STATUS.json') -Encoding UTF8
 Run-Checked 'python' @((Join-Path $PSScriptRoot 'package_project.py')) (Join-Path $root 'build/package.log')
 # Open the actual licensed build in the writable ASCII stage, avoiding stale
 # GUI snapshots and OneDrive database write errors.
 $workspace=Split-Path -Parent $root
 $guiProject=Join-Path $stage 'de2_115_nios.qpf'
 [IO.File]::WriteAllText((Join-Path $workspace 'N6_GUI_PROJECT_PATH.txt'),$guiProject)
 $launcher='@echo off'+"`r`n"
 if($env:LM_LICENSE_FILE){$launcher+='set "LM_LICENSE_FILE='+$env:LM_LICENSE_FILE+'"'+"`r`n"}
 $launcher+='start "" "'+(Join-Path $QuartusRoot 'bin64/quartus.exe')+'" "'+$guiProject+'"'+"`r`n"
 [IO.File]::WriteAllText((Join-Path $workspace 'OPEN_QUARTUS_NIOS_FINAL.cmd'),$launcher,[Text.Encoding]::ASCII)
 "PASS Nios V/c + firmware C + APB-UART + LCD SOF: $(Join-Path $root 'output_files/de2_115_nios.sof')"
 "Build stage: $stage"
} finally {Pop-Location}
