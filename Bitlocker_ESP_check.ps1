$bitlockerstatus = Get-BitLockerVolume -MountPoint C: | select VolumeStatus -ExpandProperty volumestatus
$isesprunning = Get-process -name wwahost -ErrorAction SilentlyContinue

if (($bitlockerstatus -contains "FullyEncrypted") -and ($isesprunning -eq $null))  {
    Write-Output 1
    Exit 0  
}


