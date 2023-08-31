# OPEN ICT HPIA installer tool! (found on: https://github.com/openictnl)
# Downloads and runs the vendors software (softpaqs, drivers etc) and then, silently, installs the found patches. See the README in the repo for more information!
# USE AT YOUR OWN RISK!
# 

# the parameters that can be given
param (
    [string]$location = "C:\OpenICT",
    [switch]$cleanup = $false
)

# define vendor hashtable, if not in this dict then exit directly
$vendor_dict = @{HP = "vendors/hp.ps1"; LENOVO = "lenovo/url" }
$repo_dir = "https://github.com/openictnl/HPIA-installer"

# get the vendorname from the device
$vendor = (Get-WmiObject Win32_BIOS).Manufacturer
Write-Output $vendor

if (-Not $vendor_dict.ContainsKey($vendor)) {
    throw "Update tool not available for vendor: '$vendor'." # vendor not found > exit here
}

# build installer directory
function create_directory($path) {
    mkdir -Force "$path" > $null
}
$install_dir = $location + "\" + $vendor
create_directory($install_dir)
