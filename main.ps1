# Open ICT vendor firmware installer tool! (found on: https://github.com/openictnl)
# Downloads and runs the vendors software (softpaqs, drivers etc) and then, silently, installs the found updates. See the README in the repo for more information!
# USE SCRIPT AT YOUR OWN RISK!

# The optional parameters that can be supplied
param (
    [string]$location = "C:\OpenICT",
    [switch]$cleanup = $false
)

# define vendor hashtable, if not in this dict then exit directly
$vendor_dict = @{
    HP     = "vendors/hp.ps1";
    LENOVO = "lenovo/url" 
}
$root_repo_dir = "https://raw.githubusercontent.com/openictnl/HPIA-installer/dev/multiple-vendors"

function Write-Log($message, $entrytype = "Information") {
    Write-Output $message # The acceptable values for this parameter are: Error, Warning, Information, SuccessAudit, and FailureAudit.
    Write-EventLog -LogName Application -Source "HPIA-installer-MAIN" -EntryType $entrytype -EventId 001 -Message $message
}


# get the vendorname from the device
$vendor = (Get-WmiObject Win32_BIOS).Manufacturer

if (-Not $vendor_dict.ContainsKey($vendor)) {
    Write-Log "Update tool not available for vendor: $vendor." "Error"
    exit
}

# build installer directory
function CreateDirectory($path) {
    mkdir -Force "$path" > $null
}
$install_dir = Join-Path -Path $location -ChildPath $vendor
CreateDirectory $install_dir


function DownloadScript($url, $script_path) {
    Invoke-WebRequest -Uri $url -OutFile $path
}

try {
    $vendor_script_uri = $root_repo_dir + "/" + $($vendor_dict[$vendor])
    $script_path = Join-Path -Path $install_dir -ChildPath $vendor.ToLower() + "_installer.ps1"
    DownloadScript $vendor_script_uri $script_path
}
catch {
    Write-Log "Could not download the script from the repo, please check the internet connection and try again!" "Error"
    exit
}

# run the downloaded script
& $vendor_script_uri -location $location -cleanup $cleanup
Write-Log "Started the $vendor installer script."
