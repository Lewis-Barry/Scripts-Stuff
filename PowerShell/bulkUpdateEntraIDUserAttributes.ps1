# Source: This script was taken from the below blog post and updated to use Microsoft Graph PowerShell.
# https://morgantechspace.com/2022/03/update-bulk-azure-ad-user-attributes-using-powershell.html

# Requires Microsoft.Graph.Users module
# Install: Install-Module Microsoft.Graph.Users -Scope CurrentUser
# Connect: Connect-MgGraph -Scopes "User.ReadWrite.All"

# Read user details from the CSV file - Get the source CSV from the blog post link.
$AzureADUsers = Import-CSV "C:\temp\userDetailsToBeUpdated.csv"
$i = 0;
$TotalRows = $AzureADUsers.Count
 
# Array to add update status
$UpdateStatusResult=@()
 
# Iterate and set user details one by one
ForEach($UserInfo in $AzureADUsers)
{
$UserId = $UserInfo.'UserPrincipalName'
 
# Convert CSV user info (PSObject) to hashtable
$NewUserData = @{}
$UserInfo.PSObject.Properties | ForEach { $NewUserData[$_.Name] = $_.Value }
 
$i++;
Write-Progress -activity "Processing $UserId " -status "$i out of $TotalRows completed"
 
Try
{
 
# Get current Microsoft Graph user object
$UserObj = Get-MgUser -UserId $UserId -Property "Id,UserPrincipalName,JobTitle,Department,CompanyName,OfficeLocation,City,Country,PostalCode,State,StreetAddress"
 
# Convert current user object to hashtable
$ExistingUserData = @{}
$UserObj.PSObject.Properties | ForEach { $ExistingUserData[$_.Name] = $_.Value }
 
$AttributesToUpdate = @{}
 
# The CSV header names should match Microsoft Graph user property names.
# Note: PhysicalDeliveryOfficeName is now OfficeLocation in Microsoft Graph
# Run this command to get supported properties: Get-MgUser | Get-Member -MemberType property
$CSVHeaders = @("JobTitle","Department","CompanyName","OfficeLocation","City","Country","PostalCode","State","StreetAddress")
 
ForEach($property in $CSVHeaders)
{
# Check the CSV field has value and compare the value with existing user property value.
if ($NewUserData[$property] -ne $null -and ($NewUserData[$property] -ne $ExistingUserData[$property]))
{
$AttributesToUpdate[$property] = $NewUserData[$property]
}
}
if($AttributesToUpdate.Count -gt 0)
{
# Set required user attributes.
# Need to prefix the variable AttributesToUpdate with @ symbol instead of $ to pass hashtable as parameters (ex: @AttributesToUpdate).
Update-MgUser -UserId $UserId @AttributesToUpdate
$UpdateStatus = "Success - Updated attributes : " + ($AttributesToUpdate.Keys -join ',')
 
} else {
$UpdateStatus ="No changes required"
}
 
}
catch
{
$UpdateStatus = "Failed: $_"
}
 
# Add user update status
$UpdateStatusResult += New-Object PSObject -property $([ordered]@{
User = $UserId
Status = $UpdateStatus
})
}
 
# Display the user update status result
$UpdateStatusResult | Select User,Status
 
# Export the update status report to CSV file
#$UpdateStatusResult | Export-CSV "C:\temp\AzureADUserUpdateStatus.CSV" -NoTypeInformation -Encoding UTF8
