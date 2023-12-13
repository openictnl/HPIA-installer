# HPImageAssist (HPIA) silent installer

Use this Powershell script to run the HPImageAssist tool automatic and silently in the background on any HP device. </br>
> **Warning**</br>
>This script downloads a .exe from a defined url! Be very careful when downloading files from any source on the internet. Use this script at your own risk, we are not responsible for any harm done to your device after using this tool. Downloaded files and created dirs also get deleted (when the parameter is supplied) be aware of this.

## How To
This script first downloads the latest version of the HPIA from the main HP location, then writes it into a default location (which can be overwritten) and starts the installer. </br>

### Start the script
The script should be started either by:
1. Cloning the repo and running it locally by running this command in powershell (recommended, as you can review the code):
``` powershell
powershell.exe .\installer.ps1 -location "C:\any\custom\location" -cleanup
```
2. Run it from this repo directly inside a powershell window (with or without params) by copy these commands below and paste them in a powershell window:
``` powershell
$script_location = "C:\Temp\installer.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/openictnl/HPIA-installer/master/installer.ps1" -UseBasicParsing -Outfile "$script_location"; &$("$script_location") -location "C:\OpenFoobar" -cleanup
```

### Commandline parameters
| Flag | Type | Default | Result |
| ------------- | ------------- | ------------- | ------------- |
| -location | string | C:\hpia-silent | The location where the files will be downloaded / stored
| -cleanup | bool | false | When this flag is supplied the downloaded items will be cleaned
