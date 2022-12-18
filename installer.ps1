# OPEN-ICT TOOL!
# Downloads and installs the HP image assist which then install found drivers. See the README for more information!

# Set the default location where the .exe should be downloaded into, this can be supplied as an argument via the cmdline:
# .\installer.ps1 -location "<custom path>"
param ([string]$location = "C:\hptool")

# find the download url from the static HPia page
$hpia_main_url = "https://ftp.ext.hp.com/pub/caps-softpaq/cmit/HPIA.html"
$version_url = Invoke-RestMethod $hpia_main_url | Select-String -Pattern 'href="(.*hp-hpia-.*.exe)">' | % {"$($_.matches.groups[1])"}

function create_directory($dirname){
    md -Force "$dirname" > $null
}

# create installer location if it does not exsist
create_directory($location)

# download and extract the HPIA and extract the exe
$exe_location = "$location\hpiatool.exe"
if (-not (Test-path "$exe_location" -PathType leaf) ) {
    wget "$version_url" -OutFile "$exe_location" > $null
    Set-Location -Path "$location"
    echo "...extracting image assist!"
    & ".\hpiatool.exe" /s /e /f  "$location\hptool_dir"

} 

# create the logdirs
$hpia_dir = "$location\logdir"
create_directory("$hpia_dir")

# run the imageassist tool
Set-Location -Path "$location\hptool_dir"
& ".\HPImageAssistant.exe" /Operation:Analyze /Action:Install /Silent /SoftpaqDownloadFolder:"$hpia_dir" /ReportFolder:"$hpia_dir"

echo "The HP image assist is running in the background... this will take some minutes"
Start-Sleep -Seconds 5
Exit
