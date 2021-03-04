#############################
#second script
<#
Scrath drive clean up (script 2 out of 3)
.DESCRIPTION
Script checks date and looks for current date. If there is a match it
looks for files located on TEMP drive and matches them to file from list.
It also checks the file '.LastwriteTime' timestamp (90 + 14 days), compares it with todays date.
If match is confirmed (name& path of the file match AND timestamp is 104 days) - files are moved
to new location (directory structure is also preserved).
When files are moved txt file with list of files to be moved ($txtpath) is moved to archive folder for future reference.
.INPUTS
-Scheduled Task needs to be created on server to run this script on daily basis
-Some hardcoded path needs to be updated if moved to other location

.NOTES
Written By: Kasha Kazmierczak
#>

$Now = Get-Date
$DateToFind = (Get-Date).tostring("ddMMyyyy")
$FilesLocation = "\\Server_Name\TEMP"
$TxtFileLocation = "\\Server_Name\TEMPOld$\pending\"
$TimeToKeep = "104" # 90 days plus 14
$Lastwrite =  $Now.AddDays(-$TimeToKeep)
$movelog = "\\Server_Name\TEMPOld$\log\moved"
$targetLog = "\\Server_Name\TEMPOld$\Log\Targeted"

# read date.txt file, check if any changes took place during 2 weeks interval & move files to new location

#find txt file with TODAYs date and compare it to existing files (must be todays date otherwise will not find and escapes)
#log

    $TxtFile = Get-ChildItem -Path $TxtFileLocation  -Recurse | Where-Object `
    { !$PsIsContainer -and [System.IO.Path]::GetFileNameWithoutExtension($_.Name) -eq $DateToFind }
    $txtpath = join-path $TxtFileLocation $TxtFile

    #read content and compare with datestamps on TEMPdrive files and move to new location
    $list = Get-content $txtpath

Foreach ($record in $list)
        {
            $check = resolve-path -literalPath $record -ErrorAction SilentlyContinue
            if ($check)

              {  $file = Get-Item -literalPath $record
                 if ($file.LastWriteTime -le "$Lastwrite" ) #-and $file.CreationTime -le "$Lastwrite" )
                 {
               $newpath = $file -Replace "Server_Name", "Server_Name\TEMPOld$"
               move-item -literalPath $file -Destination  $newpath
               Write-Output "Moving $file to $newpath"  | out-file "$movelog\MovedFilesLog_$DateToFind.txt" -Append
                             }
                 }

 else      { Write-Output "not moving $file "| out-file "$movelog\MovedFilesLog_$DateToFind.txt" -Append }

        }




#move txt file to archive folder

move-item $txtpath -Destination $targetLog
