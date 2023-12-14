# OPEN ICT HPIA installer tool! (found on: https://github.com/openictnl)
# Downloads and runs the HPImageAssist which then, silently, installs the found drivers. See the README in the repo for more information!
# USE AT YOUR OWN RISK!

param (
    [string]$location = "C:\OpenICT",
    [switch]$cleanup = $false,
    [switch]$eventlog = $false
)

# find the download url from this static HPia page
$hpia_main_url = "https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html"


function Write-Log($message, $entrytype = "Information") {
    $app_name = "HPIA-installer-HP"
    Write-Output $message # The acceptable values for this parameter are: Error, Warning, Information, SuccessAudit, and FailureAudit.
    if (-not $eventlog) {
        return
    }
    if (-not (Get-EventLog -LogName Application -Source $app_name)) {
        New-EventLog -LogName Application -Source $app_name
    }
    Write-EventLog -LogName Application -Source $app_name -EntryType $entrytype -EventId 002 -Message $message
}

# test if the given path exists
function PathExists($path) {
    if (Test-Path -Path "$path") {
        return $true
    }
}

function CreateDirectory($path) {
    mkdir -Force "$path" > $null
}

# download and extract the HPIA when the file is not already present on the given path
$exe_location = "$location\hpiatool.exe"
if ( -not (PathExists($exe_location)) ) {
    Write-Log "No previous installation found, searching for the latest version."
    # download latest version
    $version_url = Invoke-RestMethod $hpia_main_url | Select-String -Pattern 'href="(.*hp-hpia-.*.exe)">' | ForEach-Object { "$($_.matches.groups[1])" }
    Write-Log "Found the latest version, downloading: $version_url"
    New-Item -Path $exe_location -ItemType File -Force > $null
    Invoke-WebRequest -Uri $version_url -OutFile $exe_location
    Start-Sleep -Seconds 2
} 

# create extraction dir and extract
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

# create logdirs and start the image assist
$log_dir = "$location\hpia\logs"
CreateDirectory($log_dir)
& "$hp_extracted_dir\HPImageAssistant.exe" /Operation:Analyze /Action:Install /Silent /SoftpaqDownloadFolder:"$log_dir" /ReportFolder:"$log_dir"; Start-Sleep -Seconds 2

# when no cleanup is defined, just exit the program
if (-not ($cleanup)) {
    Write-Log "The HPImageAssist is running in the background, this will take a couple of minutes, a restart might be required!"
    Start-Sleep -Seconds 5
    Exit
}
else {
    Write-Log "Running the HPImageAssist, please wait for it to complete!"
}

# Wait for the installation to complete, then do a cleanup
function CleanupData() {
    $retries = 30
    $tries = 0
    while (-not (PathExists("$log_dir\*.json"))) {
        $tries += 1
        Start-Sleep -Seconds 10
        if ($tries -ge $retries) {
            Write-Log "The HPImageAssist is not yet completed, but this script is closing because of the time it takes!"
            return
        } 
    }
    Write-Log "The HPImageAssist is completed, starting a clean up!"
    # remove the installer and the created dirs (keep created rootdir, since it could be a sensitive one, we dont want to remove C:)
    Get-ChildItem -Path "$location\hpia" -Recurse | Remove-Item -Force -Recurse > $null
    Remove-Item "$location\hpia" -Force > $null
    Remove-Item "$exe_location" > $null
    return
}

CleanupData
Exit
