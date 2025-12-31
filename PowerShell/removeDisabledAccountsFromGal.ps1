# [TESTING] - this script has not been tested in a production environment, use at your own risk!
# Hide Disabled Entra ID Users from Global Address List
# This script finds all disabled user accounts in Entra ID and hides them from the GAL
# Uses Exchange Online PowerShell for users with mailboxes

# Required Modules:
# Install-Module Microsoft.Graph.Users -Scope CurrentUser
# Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
# Install-Module ExchangeOnlineManagement -Scope CurrentUser

# Connect to Microsoft Graph
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor Cyan
Connect-MgGraph -Scopes "User.Read.All"

# Connect to Exchange Online
Write-Host "Connecting to Exchange Online..." -ForegroundColor Cyan
Connect-ExchangeOnline

# Get all disabled user accounts
Write-Host "`nRetrieving disabled user accounts..." -ForegroundColor Cyan
$DisabledUsers = Get-MgUser -All -Filter "accountEnabled eq false" -Property Id,UserPrincipalName,DisplayName,AccountEnabled,OnPremisesSyncEnabled,Mail -ConsistencyLevel eventual

Write-Host "Found $($DisabledUsers.Count) disabled user accounts" -ForegroundColor Yellow

if ($DisabledUsers.Count -eq 0) {
    Write-Host "No disabled users found. Exiting." -ForegroundColor Green
    Disconnect-MgGraph
    Disconnect-ExchangeOnline -Confirm:$false
    #exit
}

# Array to store results
$Results = @()
$i = 0

# Process each disabled user
foreach ($User in $DisabledUsers) {
    $i++
    Write-Progress -Activity "Hiding disabled users from GAL" -Status "Processing $($User.UserPrincipalName)" -PercentComplete (($i / $DisabledUsers.Count) * 100)
    
    try {
        # Check if user has an Exchange mailbox
        $Mailbox = Get-Mailbox -Identity $User.UserPrincipalName -ErrorAction SilentlyContinue
        
        if ($null -eq $Mailbox) {
            Write-Host "No mailbox found: $($User.UserPrincipalName)" -ForegroundColor Yellow
            $Status = "No Mailbox"
            $HasMailbox = $false
            $MailboxType = "None"
        }
        elseif ($Mailbox.RecipientTypeDetails -eq "SharedMailbox") {
            Write-Host "Skipping shared mailbox: $($User.UserPrincipalName)" -ForegroundColor Cyan
            $Status = "Skipped - Shared Mailbox"
            $HasMailbox = $true
            $MailboxType = "SharedMailbox"
        }
        else {
            $HasMailbox = $true
            $MailboxType = $Mailbox.RecipientTypeDetails
            
            # Check if already hidden from address list
            if ($Mailbox.HiddenFromAddressListsEnabled -eq $true) {
                Write-Host "Already hidden: $($User.UserPrincipalName)" -ForegroundColor Gray
                $Status = "Already Hidden"
            }
            else {
                # Hide mailbox from GAL
                Set-Mailbox -Identity $User.UserPrincipalName -HiddenFromAddressListsEnabled $true
                Write-Host "Hidden from GAL: $($User.UserPrincipalName)" -ForegroundColor Green
                $Status = "Success - Hidden"
            }
        }
    }
    catch {
        Write-Host "Failed to process: $($User.UserPrincipalName) - Error: $($_.Exception.Message)" -ForegroundColor Red
        $Status = "Failed: $($_.Exception.Message)"
        $HasMailbox = "Unknown"
        $MailboxType = "Unknown"
    }
    
    # Add result to array
    $Results += [PSCustomObject]@{
        UserPrincipalName = $User.UserPrincipalName
        DisplayName = $User.DisplayName
        UserId = $User.Id
        AccountEnabled = $User.AccountEnabled
        OnPremisesSynced = $User.OnPremisesSyncEnabled
        HasMailbox = $HasMailbox
        MailboxType = $MailboxType
        Status = $Status
        ProcessedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

Write-Progress -Activity "Hiding disabled users from GAL" -Completed

# Display results
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Total disabled users processed: $($Results.Count)" -ForegroundColor Yellow
Write-Host "Users with mailboxes: $(($Results | Where-Object {$_.HasMailbox -eq $true}).Count)" -ForegroundColor Cyan
Write-Host "Users without mailboxes: $(($Results | Where-Object {$_.HasMailbox -eq $false}).Count)" -ForegroundColor Yellow
Write-Host "Shared mailboxes (skipped): $(($Results | Where-Object {$_.Status -eq 'Skipped - Shared Mailbox'}).Count)" -ForegroundColor Cyan
Write-Host "Successfully hidden: $(($Results | Where-Object {$_.Status -eq 'Success - Hidden'}).Count)" -ForegroundColor Green
Write-Host "Already hidden: $(($Results | Where-Object {$_.Status -eq 'Already Hidden'}).Count)" -ForegroundColor Gray
Write-Host "Failed: $(($Results | Where-Object {$_.Status -like 'Failed*'}).Count)" -ForegroundColor Red

# Display detailed results
Write-Host "`n=== Detailed Results ===" -ForegroundColor Cyan
$Results | Format-Table -AutoSize

# Export results to CSV
$ExportPath = "C:\Temp\HideDisabledUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$Results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
Write-Host "`nResults exported to: $ExportPath" -ForegroundColor Cyan

# Disconnect from services
Disconnect-ExchangeOnline -Confirm:$false
Disconnect-MgGraph
Write-Host "`nDisconnected from Exchange Online and Microsoft Graph" -ForegroundColor Cyan
