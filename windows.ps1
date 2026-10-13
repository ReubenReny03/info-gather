# Windows (PowerShell 5+): prints CSV row -> RAM,Storage,Storage Type,OS,Status
# Usage: .\inventory.ps1

$cs      = Get-CimInstance Win32_ComputerSystem
$model   = "$($cs.Manufacturer) $($cs.Model)"
$serial  = (Get-CimInstance Win32_BIOS).SerialNumber
$ram     = [math]::Round($cs.TotalPhysicalMemory / 1GB)
$disks   = Get-PhysicalDisk
$storage = [math]::Round(($disks | Measure-Object Size -Sum).Sum / 1GB)
$types   = ($disks | ForEach-Object {
              if ($_.BusType -eq 'NVMe') { 'NVMe' } else { $_.MediaType }
           } | Sort-Object -Unique) -join '/'
$os      = (Get-CimInstance Win32_OperatingSystem).Caption
$boot    = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$up      = New-TimeSpan -Start $boot
$status  = "Online (up {0}d {1}h)" -f $up.Days, $up.Hours

[PSCustomObject]@{
    'Model'        = $model
    'Serial Number' = $serial
    'RAM'          = "$ram GB"
    'Storage'      = "$storage GB"
    'Storage Type' = $types
    'OS'           = $os
    'Status'       = $status
} | ConvertTo-Csv -NoTypeInformation
