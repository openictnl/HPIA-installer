# OPEN ICT HPIA installer tool! (found on: https://github.com/openictnl)
# Downloads and runs the HPImageAssist which then, silently, installs the found drivers. See the README in the repo for more information!
# USE AT YOUR OWN RISK!

param (
    [string]$location = "C:\OpenICT",
    [switch]$cleanup = $false,
    [switch]$eventlog = $false
)

$vendor = "HP-firmware"
$location = Join-Path -Path $location -ChildPath "$vendor"
# The vendor tooling website where the latest version can be found
$hpia_main_url = "https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html"
$log_dir = "$location\hpia\logs"

function Write-Log($message, $entrytype = "Information") {
    $app_name = "HPIA-installer-$vendor"
    Write-Output $message # The acceptable values for this parameter are: Error, Warning, Information, SuccessAudit, and FailureAudit.
    if (-not $eventlog) {
        return
    }
    if (-not (Get-EventLog -LogName Application -Source $app_name)) {
        New-EventLog -LogName Application -Source $app_name
    }
    Write-EventLog -LogName Application -Source $app_name -EntryType $entrytype -EventId 002 -Message $message
}

function PathExists($path) {
    if (Test-Path -Path "$path") {
        return $true
    }
}

function CreateDirectory($path) {
    mkdir -Force "$path" > $null
}

# Function to download and extract the HPIA
function DownloadVendorTool($exe_location, $location, $hpia_main_url) {
    if (-not (PathExists($exe_location))) {
        Write-Log "No previous installation found, searching for the latest version."
        # download latest version
        $version_url = Invoke-RestMethod $hpia_main_url | Select-String -Pattern 'href="(.*hp-hpia-.*.exe)">' | ForEach-Object { "$($_.matches.groups[1])" }
        Write-Log "Found the latest version, downloading: $version_url"
        New-Item -Path $exe_location -ItemType File -Force > $null
        Invoke-WebRequest -Uri $version_url -OutFile $exe_location
        Start-Sleep -Seconds 2
        return
    }
    Write-Log "Previous installation found, skipping download!"
}

function ExtractHPIA($exe_location, $location) {
    $hp_extracted_dir = Join-Path -Path $location -ChildPath "hpia\extracted"
    CreateDirectory($hp_extracted_dir)

    try {
        & "$exe_location" /s /e /f "$hp_extracted_dir"; Start-Sleep -Seconds 1
    }
    catch {
        Write-Log "Could not extract the HPImageAssist, stopping the installation!" "Error"
        Start-Sleep -Seconds 5
        Exit
    }
    return $hp_extracted_dir
}

function StartImageAssist($hp_extracted_dir, $log_dir) {
    # create the logdir and start the image assist
    CreateDirectory($log_dir)
    # delete all the json files in the logdir
    Get-ChildItem -Path "$log_dir\*.json" | Remove-Item -Force -ErrorAction SilentlyContinue
    $hpia_exe = Join-Path -Path $hp_extracted_dir -ChildPath "HPImageAssistant.exe"
    try {
        Write-Host "Starting the HPImageAssist, please wait for it to complete!"
        & "$hpia_exe" /Operation:Analyze /Action:Install /Silent /LogDir:"$log_dir" /SoftpaqDownloadFolder:"$log_dir" /ReportFolder:"$log_dir"; Start-Sleep -Seconds 2
    }
    catch {
        Write-Log "Could not start the HPImageAssist, stopping the installation!" "Error"
        Start-Sleep -Seconds 5
        Exit
    }
}

function PerformCleanup($location, $exe_location, $log_dir) {
    Write-Log "The HPImageAssist is completed, starting a clean up!"
    # remove the installer and the created dirs (keep created rootdir, since it could be a sensitive one, we dont want to remove C:)
    Get-ChildItem -Path "$location\hpia" -Recurse | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue 
    Remove-Item "$exe_location" > $null
    Remove-Item "$location" > $null
    return
}

function WaitForCompletion($log_dir, $cleanup) {
    $retries = 30
    $tries = 0
    while (-not (PathExists("$log_dir\*.json"))) {
        $tries += 1
        Start-Sleep -Seconds 10
        if ($tries -ge $retries) {
            Write-Log "The HPImageAssist is not yet completed, but this script is closing because of the time it takes!" "Warning"
            return
        } 
    }

    if (-not ($cleanup)) {
        Write-Log "Installation completed successfully!"
        return
    }
    PerformCleanup $location $exe_location $log_dir
}

# Main script logic
$exe_location = "$location\hpiatool.exe"
DownloadVendorTool $exe_location $location $hpia_main_url
$hp_extracted_dir = ExtractHPIA $exe_location $location
StartImageAssist $hp_extracted_dir $log_dir
WaitForCompletion $log_dir $cleanup
