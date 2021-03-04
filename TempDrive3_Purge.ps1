#############################
#third script

<# TEMP drive clean up (script 3 out of 3)
 .DESCRIPTION
 This script should run everyday and clean old files from temporary location
 Script will look for files 90 days old + 2 weeks period of time when we waited for user
 to backup, plus another 2 weeks for safe keeping. Total = 118 days
 .INPUTS
-Scheduled Task needs to be created on server to run this script on daily basis
-Some hardcoded path needs to be updated if moved to other location
.NOTES
Written By: Kasha Kazmierczak
   #>
$Now = Get-Date
$DateToFind = (Get-Date).tostring("ddMMyyyy")
$TimeToKeep = "118" # 90 days plus 28
$Lastwrite =  $Now.AddDays(-$TimeToKeep)
$FilesLocation = "\\Server_Name\TEMPOld$\TEMP"
$deletelog = "\\Server_Name\TEMPOld$\Log\Deleted"

Foreach ($File in (Get-ChildItem $FilesLocation -Recurse | where {$_.CreationTime -le "$Lastwrite"} | Where { $_.PSisContainer -eq $false }))

{

    Remove-Item $file.FullName
	Write-Host "Deleting $file" -ForegroundColor Gray
	Write-Output "Deleting $file "  | out-file "$deletelog\DeletedFilesLog_$DateToFind.txt" -Append
	}
