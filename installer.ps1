# OPEN ICT HPIA installer tool! (found on: https://github.com/openictnl)
# Downloads and runs the HPImageAssist which then, silently, installs the found drivers. See the README in the repo for more information!
# USE AT YOUR OWN RISK!

# Set the default location where the .exe should be downloaded into, this can be supplied as an argument via the cmdline:
# .\installer.ps1 -location "<custom path>"
# want to do a cleanup of the items after the installer ran, append the -cleanup argument when calling this script
# .\installer.ps1 -location "<custom path>" -cleanup

param (
    [string] $location = "C:\hpia-silent",
    [switch] $cleanup
)

# find the download url from the static HPia page
$hpia_main_url = "https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html"

# creates a directory at a given path
function create_directory($path) {
    md -Force "$path" > $null
}

# test if the given path exsists
function path_exsists($path) {
    if (Test-Path -Path "$path") {
        return $true
    }
}

# create the root installer dir
create_directory($location)

# download and extract the HPIA when the file is not already present on the given path
$exe_location = "$location\hpiatool.exe"
if ( -not (path_exsists($exe_location)) ) {
    echo "... No previous installation found, finding the latest version."
    create_directory($location)
    # download latest version
    $version_url = Invoke-RestMethod $hpia_main_url | Select-String -Pattern 'href="(.*hp-hpia-.*.exe)">' | % {"$($_.matches.groups[1])"}
    wget "$version_url" -OutFile "$exe_location" > $null; Start-Sleep -Seconds 2
} 

# create extraction dir and extract
$hp_extracted_dir = "$location\hpia\extracted"
create_directory($hp_extracted_dir)
try {
    & "$exe_location" /s /e /f "$hp_extracted_dir"; Start-Sleep -Seconds 1
}
catch {
    echo "... Could not complete the installation, shutting down!"
    Start-Sleep -Seconds 5
    Exit
}

# # create logdirs and start the image assist
$log_dir = "$location\hpia\logs"
create_directory($log_dir)
& "$hp_extracted_dir\HPImageAssistant.exe" /Operation:Analyze /Action:Install /Silent /SoftpaqDownloadFolder:"$log_dir" /ReportFolder:"$log_dir"; Start-Sleep -Seconds 2

# when no cleanup is set, just exit the program
if (-not ($cleanup)) {
    echo "The HPImageAssist is running in the background, this will take a couple of minutes."
    Start-Sleep -Seconds 5
    Exit
} else {
    echo "... Running the HPImageAssist, please wait for it to complete and dont reboot your device!"
}

# # Wait for the installation to complete, then do a cleanup
function cleanup_data() {
    $retries = 30
    $tries = 0
    while (-not (path_exsists("$log_dir\*.json"))) {
        $tries += 1
        Start-Sleep -Seconds 10
        if ($tries -ge $retries) {
            echo "The HPImageAssist is still not completed, but script is shutting down because of the time it took!"
            return
        } 
    }
    echo "HPImageAssist is completed, cleaning up!"
    # remove the installer and the created dirs (keep created rootdir, since it could be a sensitive one, we dont want to remove C:)
    Get-ChildItem -Path "$location\hpia" -Recurse | Remove-Item -force -recurse > $null
    Remove-Item "$location\hpia" -Force > $null
    Remove-Item "$exe_location" > $null
    return
}

cleanup_data
Exit
