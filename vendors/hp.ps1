# OPEN ICT HPIA installer tool! (found on: https://github.com/openictnl)
# Downloads and runs the HPImageAssist which then, silently, installs the found drivers. See the README in the repo for more information!
# USE AT YOUR OWN RISK!

# Set the default location where the .exe should be downloaded into, this can be supplied as an argument via the cmdline:
# .\installer.ps1 -location "<custom path>"
# want to do a cleanup of the items after the installer ran, append the -cleanup argument when calling this script
# .\installer.ps1 -location "<custom path>" -cleanup

param (
    [string] $location,
    [switch] $cleanup
)

# find the download url from this static HPia page
$hpia_main_url = "https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html"
#
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
    Write-Output "... No previous installation found, finding the latest version."
    # download latest version
    $version_url = Invoke-RestMethod $hpia_main_url | Select-String -Pattern 'href="(.*hp-hpia-.*.exe)">' | ForEach-Object { "$($_.matches.groups[1])" }
    wget "$version_url" -OutFile "$exe_location" > $null; Start-Sleep -Seconds 2
} 

# create extraction dir and extract
$hp_extracted_dir = Join-Path -Path $location -ChildPath "hpia\extracted"
CreateDirectory($hp_extracted_dir)
try {
    & "$exe_location" /s /e /f "$hp_extracted_dir"; Start-Sleep -Seconds 1
}
catch {
    Write-Output "... Could not complete the installation, stopping installation!"
    Start-Sleep -Seconds 5
    Exit
}

# create logdirs and start the image assist
$log_dir = "$location\hpia\logs"
CreateDirectory($log_dir)
& "$hp_extracted_dir\HPImageAssistant.exe" /Operation:Analyze /Action:Install /Silent /SoftpaqDownloadFolder:"$log_dir" /ReportFolder:"$log_dir"; Start-Sleep -Seconds 2

# when no cleanup is defined, just exit the program
if (-not ($cleanup)) {
    Write-Output "The HPImageAssist is running in the background, this will take a couple of minutes."
    Start-Sleep -Seconds 5
    Exit
}
else {
    Write-Output "... Running the HPImageAssist, please wait! DO NOT REBOOT YOUR DEVICE!"
}

# Wait for the installation to complete, then do a cleanup
function CleanupData() {
    $retries = 30
    $tries = 0
    while (-not (PathExists("$log_dir\*.json"))) {
        $tries += 1
        Start-Sleep -Seconds 10
        if ($tries -ge $retries) {
            Write-Output "The HPImageAssist is still not completed, but script is shutting down because of the time it took!"
            return
        } 
    }
    Write-Output "HPImageAssist finished, cleaning up!"
    # remove the installer and the created dirs (keep created rootdir, since it could be a sensitive one, we dont want to remove C:)
    Get-ChildItem -Path "$location\hpia" -Recurse | Remove-Item -Force -Recurse > $null
    Remove-Item "$location\hpia" -Force > $null
    Remove-Item "$exe_location" > $null
    return
}

CleanupData
Exit
