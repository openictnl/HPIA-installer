# Vendor Firmware Installer Tool

This PowerShell script is designed to download and run vendor software (such as softpaqs, drivers, etc.) and then silently install the found updates. It's part of the Open ICT project and can be found on [GitHub](https://github.com/openictnl).

## Warning
This script downloads files from the internet. Always make sure you trust the source of the files before running the script. ***Use this script at your own risk.***

## How it Works

The script accepts 3 optional parameters:

- `location`: This is the directory where the downloaded files will be stored. The default location is `C:\OpenICT`.
- `cleanup`: This is a switch parameter. If it's included, the script will clean up the downloaded files after the installation. default is false.
- `eventlog`: This is a switch parameter. If it's included, the script will log events to the Windows Event Log. default is false.

The script first identifies the vendor of the device by querying the BIOS. It then checks if the vendor is supported by looking up a predefined hashtable. If the vendor is supported, the script creates a directory for the installation files and downloads the necessary scripts from the Open ICT repository.

### Requirements
- PowerShell 5.1 or higher
- Windows 10 1809 or higher

Tested on windows 11 with powershell 7

## Usage
You can run the script in PowerShell with the following command (after downloading it locally):

```powershell
.\main.ps1 -location "C:\CustomLocation" -cleanup -eventlog
```
Replace `C:\CustomLocation` with your desired location. Include `-cleanup`  if you want the script to clean up the downloaded files after the installation and add -eventlog if you want the script to log events to the Windows Event Log.

Or you can run the script directly from this repo with the following command:
```powershell
# Define the URL of the script
$scriptUrl = "https://raw.githubusercontent.com/openictnl/HPIA-installer/master/main.ps1"
# Download the script
$script = Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing
# Execute the script with parameters
Invoke-Expression "& { $script.Content } -cleanup -eventlog"
```

### Commandline parameters
| Flag | Type | Default | Result |
| ------------- | ------------- | ------------- | ------------- |
| -location | string | C:\OpenICT | The location where the files will be downloaded / stored
| -cleanup | bool | false | When this flag is supplied the downloaded items will be cleaned
| -eventlog | bool | false | When this flag is supplied the script will log events to the Windows Event Log


## Examples
To specify a custom location for the downloaded files without cleaning up the files after the installation and to not write out an event to the Windows Event Log, run the following command:
```powershell
.\main.ps1 -location "C:\MyCustomLocation"
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
For vendors that are not yet supported, please open an issue with the vendor name and the BIOS vendor ID (you can find this by running `Get-WmiObject -Class Win32_BIOS` in PowerShell).

## License
[MIT](https://choosealicense.com/licenses/mit/)
