# Native Windows/Quartus tools only; no Python/terminal application required.
function Get-De2Target {
    param([string[]]$Lines)
    $cable=0;$device=0;$targets=@()
    foreach($line in $Lines){
        if($line -match '^\s*(\d+)\)\s+(.+)$'){$cable=[int]$Matches[1];$device=0}
        elseif($cable -gt 0 -and $line -match '^\s*([0-9A-Fa-f]{8})\s+(.+)$'){
            $device++
            $id=$Matches[1];$deviceName=$Matches[2]
            # Quartus can abbreviate this shared device ID as
            # 10CL120(Y|Z)/EP3C120/.. instead of spelling out EP4CE115.
            # The board model is DE2-115; Programmer also validates the SOF ID.
            if($id -eq '020F70DD' -or $deviceName -match '\bEP4CE115\b'){
                $targets+= [PSCustomObject]@{Cable=$cable;Device=$device;Id=$id;Name=$deviceName}
            }
        }
    }
    return $targets
}
function Select-UartPort {
    param([string[]]$Ports,[string[]]$Baseline,[string]$Requested)
    if($Requested){
        if($Ports -notcontains $Requested){throw "Requested serial port $Requested is not present"}
        return $Requested
    }
    $newPorts=@($Ports | Where-Object {$Baseline -notcontains $_})
    if($newPorts.Count -eq 1){return $newPorts[0]}
    throw "Cannot select UART unambiguously. Present: $($Ports -join ', '); new: $($newPorts -join ', '). Use -Port COMx."
}
function Invoke-LabNative {
    param([string]$Exe,[string[]]$Arguments,[string]$Log)
    $ErrorActionPreference='Continue'
    $lines=@(& $Exe @Arguments 2>&1 | ForEach-Object {"$_"})
    $code=$LASTEXITCODE
    $lines | Set-Content -LiteralPath $Log -Encoding UTF8
    return [PSCustomObject]@{Code=$code;Lines=$lines}
}
function Test-ReadyFiles {
    param([string]$Root)
    $manifest=Import-Csv -LiteralPath (Join-Path $Root 'SHA256SUMS.csv')
    $files=@($manifest | Where-Object {$_.path -match '^rtl/|^output_files/.+\.sof$'})
    if($files.Count -ne 14){throw 'Expected 13 RTL files and one SOF in hash manifest'}
    foreach($file in $files){
        $actual=(Get-FileHash -LiteralPath (Join-Path $Root $file.path) -Algorithm SHA256).Hash
        if($actual -ne $file.sha256){throw "Ready-file hash mismatch: $($file.path). Rebuild and revalidate before programming."}
    }
}
function Invoke-UartExchange {
    param($Serial,[byte[]]$Payload)
    $Serial.Write($Payload,0,$Payload.Length)
    $received=New-Object byte[] $Payload.Length
    $offset=0;$watch=[Diagnostics.Stopwatch]::StartNew()
    while($offset -lt $received.Length){
        if($watch.Elapsed.TotalSeconds -gt 5){throw "UART timeout: $offset/$($Payload.Length) bytes"}
        try{$offset+=$Serial.Read($received,$offset,$received.Length-$offset)}
        catch [TimeoutException] {continue}
    }
    for($i=0;$i -lt $Payload.Length;$i++){
        if($received[$i] -ne $Payload[$i]){throw "UART mismatch at byte $i : sent $($Payload[$i]), received $($received[$i])"}
    }
    return ,$received
}
