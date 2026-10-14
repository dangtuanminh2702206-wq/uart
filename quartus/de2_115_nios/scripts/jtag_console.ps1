param([string]$Text,[switch]$Interactive,[int]$Cable=1,[int]$Device=1,[int]$Seconds=5)
$ErrorActionPreference='Stop'
$exe='C:/altera_lite/25.1std/quartus/bin64/juart-terminal.exe'
if($Interactive){& $exe -q -c $Cable -d $Device -i 0;exit $LASTEXITCODE}
if(!$PSBoundParameters.ContainsKey('Text')){$Text='HELLO'}
if($Text -match '[^\x00-\x7F]'){throw 'Use ASCII text for the LCD'}
$info=New-Object Diagnostics.ProcessStartInfo
$info.FileName=$exe;$info.Arguments="-q -c $Cable -d $Device -i 0 -o $Seconds"
$info.UseShellExecute=$false;$info.CreateNoWindow=$true
$info.RedirectStandardInput=$true;$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
$process=New-Object Diagnostics.Process;$process.StartInfo=$info
try{
 $null=$process.Start();$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
 $process.StandardInput.Write($Text);$process.StandardInput.Flush()
 if(!$process.WaitForExit(($Seconds+5)*1000)){$process.Kill();throw 'JTAG terminal timeout'}
 $rx=$stdout.Result;$err=$stderr.Result
 if($process.ExitCode -ne 0){throw "JTAG connection failed: $err"}
 Write-Output "RX: $rx"
 if(!$rx.Contains($Text)){throw 'Expected Echo was not received. Check SW0=1 then KEY0; inspect LCD/LEDs.'}
 'PASS JTAG text echoed through CPU, Avalon/APB and internal serial UART loopback.'
}finally{$process.Dispose()}
