#This Script needs to be executed as an administrator

#Set variables for hostname, old_domain and new_domain 
#IMPORTANT: Domain names need to be specified as the logon (for example: INTERNAL -> Good, internal.iaagdev.com -> bad)

$PC = hostname
$old_domain = "serverabd" # you have to change
$new_domain = "serverabd2" # you have to change

#Set path of Backup location and USMT Tool location

$Folder = 'C:\tm\Backup\' + $PC # you have to change
$USMTPath = 'C:\tm\Windows Kits\10\Assessment and Deployment Kit\User State Migration Tool\amd64' # you have to change

#Set Path of .csv file and import the csv

#$csvPath = ".\MigrationTable.csv"

#Hardcoded Path for testing
$csvPath = "C:\tm\Liste\MigrationTable.csv" # you have to change
$user_list = Import-Csv $csvPath -Encoding UTF8 -Delimiter ';'

#Save old and new Username in their respective variables

$user_list | Where-Object {$_.Hostname -eq $PC}| foreach{
$old_username= $_.Username_old_domain
$new_username= $_.Username_new_domain
}

#Test if the Backup folder already exists
#If not set Path to location of USMT Tool
#And execute scanstate command

"Test to see if folder [$Folder] exists"
if (Test-Path -Path $Folder) {
    "Path exists!"
    Exit
} else {
    "Path doesnt't exist."
    $PC = hostname
    Write-Host $PC
    cd $USMTPath

    $backup_process = .\scanstate $Folder /i:migapp.xml /i:migDocs.xml /v:13 /l:scan.log /ue:*\* /ui:$old_username
    Get-Process -Id $backup_process
    Wait-Process -Id $backup_process -ErrorAction Stop

    #Join PC to Domain
    #Do not restart the PC before the Script is finished!

    $domain = "serverabd2" # you have to change
    $UserName = "$domain\administrator" # you have to change
    $Password = "password" | ConvertTo-SecureString -AsPlainText -Force # you have to change
    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName,$Password
    Add-Computer -DomainName $domain -DomainCredential $Credential -Verbose

    #Execute loadstate command
    #Profile is restored and assigned to new user
    cd $USMTPath
    $restore_process = .\loadstate /i:migapp.xml /i:miguser.xml $Folder /progress:prog.log /l:load.log /mu:$old_domain\${old_username}:$new_domain\$new_username
    Get-Process -Id $restore_process
    Wait-Process -Id $restore_process
    #Muss das Script noch hinter sich aufräumen?

    Restart-Computer
}



