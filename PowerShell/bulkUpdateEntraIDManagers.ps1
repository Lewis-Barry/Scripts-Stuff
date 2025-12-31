# Source: This script was taken from the below blog post and updated to use Microsoft Graph PowerShell.
# https://morgantechspace.com/2022/09/update-manager-for-bulk-azure-ad-users-using-powershell.html

# Requires Microsoft.Graph.Users module
# Install: Install-Module Microsoft.Graph.Users -Scope CurrentUser
# Connect: Connect-MgGraph -Scopes "User.ReadWrite.All"

#Read user details from the CSV file - Get the source CSV from the blog post link.
$CSVRecords = Import-CSV "C:\Temp\ManagerUpdate.csv"
$i = 0;
$TotalRows = $CSVRecords.Count
 
#Array to add the status result
$UpdateResult=@()
 
#Iterate CSVRecords (users) and set manager for users one by one
Foreach($CSVRecord in $CSVRecords)
{
$UserUPN = $CSVRecord.'UserUPN'
$ManagerUPN = $CSVRecord.'ManagerUPN'
 
$i++;
Write-Progress -activity "Processing $UserUPN (Manager-$ManagerUPN)" -status "$i out of $TotalRows users completed"
 
Try
{
 
#Set-MgUserManagerByRef cmdlet - the parameter requires the manager's ObjectId.
#The below command retrieves the ObjectId using the manager's UPN
$ManagerObj = Get-MgUser -UserId $ManagerUPN
 
#Set the manager - requires the full OData reference format
Set-MgUserManagerByRef -UserId $UserUPN -OdataId "https://graph.microsoft.com/v1.0/users/$($ManagerObj.Id)"
#Set update status
$UpdateStatus = "Success"
}
catch
{
$UpdateStatus = "Failed: $_"
}
 
#Add update status to the result array
$UpdateResult += New-Object PSObject -property $([ordered]@{
UserUPN = $UserUPN
ManagerUPN = $ManagerUPN
Status = $UpdateStatus
})
 
}
 
#Display the update status result 
$UpdateResult | Select UserUPN,ManagerUPN,Status
 
#Export the update status report to a CSV file
#$UpdateResult | Export-CSV "C:\Temp\UpdateManagerStatus.CSV" -NoTypeInformation -Encoding UTF8
