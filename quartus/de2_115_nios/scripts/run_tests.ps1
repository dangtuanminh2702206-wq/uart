$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Path (Join-Path $root 'build') -Force | Out-Null
function Invoke-CheckedNative {
 param([string]$Exe,[string[]]$ToolArgs)
 $ErrorActionPreference='Continue'
 $text=@(& $Exe @ToolArgs 2>&1 | ForEach-Object {"$_"})
 $code=$LASTEXITCODE
 $text | Write-Output
 if($code -ne 0){throw "$Exe failed with exit code $code"}
}
Push-Location $root
try {
 Invoke-CheckedNative 'python' @('scripts/build_firmware.py')
 & python scripts/test_firmware.py | Tee-Object -FilePath build/firmware_test.log
 if($LASTEXITCODE -ne 0){throw 'Firmware test failed'}
 $sources=@(Get-ChildItem core -Recurse -Filter *.v | Where-Object {$_.Name -notin @('apb_echo_master.v','uart_apb_echo_system.v','de2_115_apb_echo_top.v')} | ForEach-Object {$_.FullName})
 & iverilog -g2001 -Wall -Wno-timescale -s tb_nios_uart_peripheral -o build/peripheral.vvp rtl/nios_uart_peripheral.v tb/tb_nios_uart_peripheral.v @sources
 if($LASTEXITCODE -ne 0){throw 'Peripheral compile failed'}
 $output=@(& vvp build/peripheral.vvp)
 $code=$LASTEXITCODE;$output | Tee-Object -FilePath build/peripheral_test.log
 if($code -ne 0 -or !($output -match '^PASS')){throw 'Peripheral simulation failed'}
 'PASS all Nios preparation tests (firmware + bridge/UART RTL). Not a physical board test.'
} finally {Pop-Location}
