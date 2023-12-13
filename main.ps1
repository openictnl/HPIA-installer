# OPEN ICT HPIA installer tool! (found on: https://github.com/openictnl)
# Downloads and runs the vendors software (softpaqs, drivers etc) and then, silently, installs the found patches. See the README in the repo for more information!
# USE AT YOUR OWN RISK!
# 

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
# $repo_dir = "https://github.com/openictnl/HPIA-installer/tree/dev/multiple-vendors"
$repo_dir = "https://raw.githubusercontent.com/openictnl/HPIA-installer/dev/multiple-vendors"

# get the vendorname from the device
$vendor = (Get-WmiObject Win32_BIOS).Manufacturer

if (-Not $vendor_dict.ContainsKey($vendor)) {
    throw "Update tool not available for vendor: $vendor." # vendor not found > exit here
    exit
}

# build installer directory
function CreateDirectory($path) {
    mkdir -Force "$path" > $null
}
$install_dir = Join-Path -Path $location -ChildPath $vendor
CreateDirectory $install_dir

# invoke and start the script based on the vendor
$vendor_script = $vendor_dict[$vendor]
Invoke-Expression "$repo_dir/$vendor_script" -ExecutionPolicy Bypass

#Invoke-Expression (Invoke-RestMethod -Uri $repo_dir/$vendor_script) -ArgumentList @{"location" = $install_dir; "cleanup" = $cleanup } -ExecutionPolicy Bypass
#Invoke-Expression "& 'https://raw.githubusercontent.com/username/repository/master/script.ps1' -Name 'bar' -kek 'lol' -ExecutionPolicy Bypass"


# Invoke-Expression (Invoke-RestMethod -Uri $repo_dir/$vendor_script) -location $install_dir -cleanup -ExecutionPolicy Bypass
# OPEN ICT HPIA installer tool! (found on: https://github.com/openictnl)
