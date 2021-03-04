# TEMP-Drive-cleaner

This script was used to automate the clean up of a "Temp" drive on a corporate file server which had become a dumping ground for random user files over many years. Files older then XX days were targeted and emails sent to the file owner.

Script iterates through all files located on TEMP drive. Checks the file '.LastwriteTime' timestamp, compares it with todays day and writes list of files 'older' than 90 days to txt file with todays date. Based on this list email notifications are sent out to owners of each file with information that old files will be deleted in 14 days time and user should take actions if wants to preserve them.

--

Tip: Run fortnightly as a scheduled task to generate report and send email to users automatically: program : `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe Arguments: -ExecutionPolicy bypass -NonInteractive -WindowStyle Normal -NoExit -File path\file.ps1`

--

The majority of the PS1 was written by a colleague. my contribution was the HTML emailer section and implementation on the corp file server.

'![](/images/2021/03/ScreenShot.png)'
