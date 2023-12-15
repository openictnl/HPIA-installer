# Open ICT vendor firmware installer tool! (found on: https://github.com/openictnl)
# Downloads and runs the vendors software (softpaqs, drivers etc) and then, silently, installs the found updates. See the README in the repo for more information!
# USE SCRIPT AT YOUR OWN RISK!

param (
    [string]$location = "C:\OpenICT",
    [switch]$cleanup = $false,
    [switch]$eventlog = $false
)

$vendor_dict = @{
    HP     = "vendors/hp.ps1";
    LENOVO = "lenovo/url" 
}
$root_repo_dir = "https://raw.githubusercontent.com/openictnl/HPIA-installer/dev/multiple-vendors"

function Write-Log($message, $entrytype = "Information") {
    $app_name = "HPIA-installer-MAIN"
    Write-Output $message # The acceptable values for this parameter are: Error, Warning, Information, SuccessAudit, and FailureAudit.
    if (-not $eventlog) {
        return
    }
    if (-not (Get-EventLog -LogName Application -Source $app_name)) {
        New-EventLog -LogName Application -Source $app_name
    }
    Write-EventLog -LogName Application -Source $app_name -EntryType $entrytype -EventId 001 -Message $message
}

function CreateDirectory($path) {
    mkdir -Force "$path" > $null
}

function DownloadScript($url, $script_path) {
    New-Item -Path $script_path -ItemType File -Force > $null
    Invoke-WebRequest -Uri $url -OutFile $script_path
}

function InstallVendorSoftware($vendor, $location, $cleanup, $eventlog) {
    $install_dir = Join-Path -Path $location -ChildPath $vendor
    CreateDirectory $install_dir

    $vendor_script_uri = $root_repo_dir + "/" + $($vendor_dict[$vendor])
    $scriptname = $vendor.ToLower() + "_installer.ps1"
    $script_path = Join-Path -Path $install_dir -ChildPath $scriptname

    try {
        DownloadScript $vendor_script_uri $script_path
    }
    catch {
        Write-Log "Could not download the script from the repo, please check the internet connection and try again!" "Error"
        exit
    }

    $script_parameters = "-location $location"
    if ($eventlog) {
        $script_parameters += " -eventlog"
    }

    if ($cleanup) {
        $script_parameters += " -cleanup"
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$script_path`" $script_parameters" -Wait
        Write-Log "Cleanup enabled, removing the installation directory: $install_dir"
        Remove-Item -Path $install_dir -Recurse -Force > $null
    }
    else {
        Write-log "Starting the $vendor firmware installer in the background, please wait for it to complete!"
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$script_path`" $script_parameters"
    }
}

# Get the vendorname from the device
$vendor = (Get-WmiObject Win32_BIOS).Manufacturer

if (-Not $vendor_dict.ContainsKey($vendor)) {
    Write-Log "Update tool not available for vendor: $vendor." "Error"
    exit
}

InstallVendorSoftware $vendor $location $cleanup $eventlog
