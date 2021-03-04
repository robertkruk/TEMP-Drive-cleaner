<#
TEMP drive clean up (script 1 out of 3)
.DESCRIPTION
Script iterates through all files located on TEMP drive.
Checks the file '.LastwriteTime' timestamp, compares it with todays day
and writes list of files 'older' than 90 days to txt file with todays date.
Based on this list email notifications are sent out to owners of each file
with information that old files will be deleted in 14 days time and user
should take actions if wants to preserve them.

.INPUTS
No inputs required, however some hardcoded path needs to be updated if moved to other location
.OUTPUTS
-Creates txt file with list of files to be deleted
-Sends an HTML email with list of files that will be deleted in 14 days
.EXAMPLE
.\1.ps1
Tip: Run fortnightly as a scheduled task to generate report and send email to users automatically:
program :   C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Arguments:  -ExecutionPolicy bypass -NonInteractive -WindowStyle Normal  -NoExit -File path\file.ps1
.NOTES
Written By: Kasha Kazmierczak
#>

##############################################################################################################################
#FIND OLD FILES
$Now = Get-Date
$date = (Get-Date).tostring("ddMMyyyy")
$TimeToKeep = "90" #90 days old
#LOCATION - change to "\\Server_Name\TEMP\foo\" (where foo is test folder) for testing.
$Location = "\\Server_Name\TEMP\"
$Destination = "\\Server_Name\TEMPOld$"
$Lastwrite = $Now.AddDays(-$TimeToKeep)
$enddate = (Get-Date).adddays(+14).tostring("ddMMyyyy") # today + 14 days
$ListOfDirectories = '\\Server_Name\TEMPOld$\pending\ListOfDirectories.txt'
$Unique = "\\Server_Name\TEMPOld$\pending\unique.txt"
$listD = "\\Server_Name\TEMPOld$\pending\list.txt"
$FilesList = '\\Server_Name\TEMPOld$\pending\' + $enddate + '.txt'
#Find files older than 90 days -get file name and location
$Files = Get-Childitem $Location -Recurse | where {$_.LastwriteTime -le "$Lastwrite" -and $_.CreationTime -le "$Lastwrite" } `
|where { ! $_.PSIsContainer } | % {$_.FullName} | out-file $FilesList  # Creates txt file with 2 weeks time date
#get Directory where files are located, save as txt
$ListDir = Get-content $FilesList

Foreach ($record in $ListDir)
{split-path -parent $record | Out-File $ListD -Append}

#get only unique paths
Get-content $ListD | Sort-Object -unique | Out-File $Unique

remove-item $ListD

###############################################################################################################################
#LOCATION

#replace current path with new one or add extra folder to existing path
$arrayunique = Get-content $Unique
($arrayunique) |  ForEach-Object {$_ -Replace "Server_Name", "Server_Name\TEMPOld$"} | Set-Content $listD #path swap from 'TEMP' to TEMPold$'#
# Invoke-Item $Unique
$arrayunique = Get-content $listD

#create array of locations and replicate them in destination folder, if exists escape
ForEach ($i in $arrayunique) {
if(!(test-path $i -PathType Container)){

New-Item $i -type Container
}

else{write-host "$i already exists"}
}


#################################################################################################################################
#OWNERSHIP
#create array of files with ownership info


$Reports = @()

$usernames = @()

Foreach ($File in (Get-ChildItem $Location -Recurse | where {$_.LastwriteTime -le "$Lastwrite" -and $_.CreationTime -le "$Lastwrite" } | Where { $_.PSisContainer -eq $false }))

{

   $Reports += New-Object PSObject -Property @{
		'Path' = $File.FullName
		#'Last Write Time' = $File.LastWriteTime
		'Owner' = (Get-Acl $File.FullName).Owner | Sort-Object -Property owner }

    $usernames +=  New-Object PSObject -Property @{
       # 'SamAccountName' = (Get-Acl $File.FullName).Owner.trim("DOMAIN\")}
         'SamAccountName' = (Get-Acl $File.FullName).Owner.Substring(11) } #cut 'DOMAIN\'

	}

#sort users
$u = $usernames | Sort-Object -Property SamAccountName -Unique
#check user in AD
$ownerADNames = $u | % {(Get-ADUser $_.SamAccountName).SamAccountName}

#################################################################################################################################
#EMAIL USERS
# create email for each user with list of  files that are 90 days old

$ExchangeServer = "outboundsmtp.DOMAIN.com"
$FromAddress = "noreply@DOMAIN.com"

function SendNotification{

  $Msg = New-Object Net.Mail.MailMessage
  $Smtp = New-Object Net.Mail.SmtpClient($ExchangeServer)
#Image Attachment - change location and file as required.
  $att = new-object Net.Mail.Attachment('\\Server_Name\TEMPold$\Reminder.jpg')
  $att.ContentDisposition.Inline = $True
  $att.ContentDisposition.DispositionType = "Inline"
  $att.ContentType.MediaType = "image/jpeg"
  $att.ContentId = "logo"
  $Msg.From = $FromAddress
  $Msg.To.Add($ToAddress)
  $Msg.Subject = "TEMP Drive Clean Up"
  $Msg.Body = $EmailBody
  $Msg.IsBodyHTML = $true
  $msg.Attachments.Add($att)
  $Smtp.Send($Msg)
  $att.Dispose()
  }



foreach ($user in $ownerADNames)
        { if (dsquery user -samid $user){

    $email = $user | % {(Get-ADUser $_ -properties mail).mail} -ErrorAction SilentlyContinue
    $files = $Reports -match $user | ConvertTo-Html | out-string -ErrorAction SilentlyContinue

    $ToAddress = $email
    $Name = $user

#HTML HEAD#
    $htmlhead="<html>
			<style>
			BODY{font-family: Calibri,Arial,Tahoma,Geneva,sans-serif;font-size:12pt;}
			H1{font-size: 16px;}
			H2{font-size: 14px;}
			H3{font-size: 12px;}
			TABLE{border: 1px solid black; border-collapse: collapse; font-size: 11pt;}
			TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
			TD{border: 1px solid black; padding: 5px; }

			</style>
			<body>
			<h1 align=""center"">TEMP DRIVE NOTIFICATION</h1>
			<p />
      <img src='cid:logo'>"


#HTML BODY#
    $HTMLBody = "
   <p />
    Dear $Name,
    <p />
    This is courtesy email to advise we have identified a number of files located on the TEMP drive that are over 90 days old.
    <br />
    <span style='background:#ffecec'>These files will be removed in 14 days.</span>
    <p />
    <p />
    <p /> Files to be removed:
    <p /> $files </p>
    <p /> Tech Support are always available to assist and we are offering our personal service to help you move any files and folders.
    <br /> If files from above list are important to you please assist save them in permanent storage location such as a team folder,
    <br /> My Documents folder on your computer, Confluence or SharePoint.
    "
#HTML RULES#
$HTMLRules = "
<p />
	<table>
		<tr>
		<th style='background-color: #e3f7fc'>RULES</th>
			</tr>
			<td>
				<br />We would like to take this opportunity to inform you about our TEMP drive rules:
				<ul>
				<li>Do not place files directly into the Root of TEMP drive, create a sub-folder.</li>
				<li>Files on TEMP are NOT BACKED UP.</li>
				<li>Files will be removed after 'Created' and 'Modified date is older than 90 days.</li>
				<li>Email with notification will be sent ONLY to owner of the file.</li>
				<li>Files created by local users or users without valid email address will be disposed without notification.</li>
				<li>Do not store any confidential data on TEMP drive</li>
				</ul>
			</td>
	</table>
<p />
    <span style='background:#fff8c4'>Please note:</span>
    <ul>
		<li >The files were identified as older than 90 days based on the 'Created' and 'Modified' dates.</li>
        <li>This does not mean the file has been located on the TEMP drive for over 90 days.</li>
        <li>The ‘Owner’ of the file will be notified via email.</li>
        <li>The the ‘Owner’ is the person who created the file, but the file could be located in a different folder.</li>
    </ul>
"

#HTML TAIL / END#
	$htmltail = "
    <p />Kind Regards,
    <p /> <b> Tech Support</b>
    <br />T + 61 71234 5678
    <br />E techsupport@DOMAIN.com
    <p />
    </body>
    </html>
    "

###HTML REPORT###
$EmailBody = $htmlhead + $htmlbody + $HTMLRules + $htmltail

#Powershell Output Notification
     Write-Host "Sending notification to $Name ($ToAddress)" -ForegroundColor Yellow

SendNotification
    }
}




#################################################################################################################################
#clean up
remove-item $Unique
remove-item $ListD
