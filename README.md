# HP image assist (HPIA) silent installer

Use this Powershell script to run the HP image assistance in automated and silent fashion in the background on any device. </br>
> **Warning**</br>
>This script downloads a .exe from a defined url! Be very careful when downloading files from any source on the internet. Use this script at your own risk, we are not responsible for any harm done to your device after using this tool. 

## How To
This script first downloads the latest version of the HPIA from the main HP location, then writes it into a default location (which can be overwritten) and starts the installer. </br>
DO NOTE: this script does not wait till the installation is finished or checks if it gets started correctly!

### Start the script
The script can be started in two main ways:
1. Clone the repo and run it.
2. Run directly from this source via powershell (see warning above ^) by pasting the commands below in a powershell window:
``` powershell
$OpenICT_installer_script = Invoke-WebRequest "https://raw.githubusercontent.com/openictnl/HPIA-installer/master/installer.ps1"; Invoke-Expression $($OpenICT_installer_script.Content)
```

## Change default installation directory
The default directory can be changed by parsing an argument on the cmdline:
``` powershell
powershell.exe .\installer.ps1 -location "C:\any\custom\location"
```

