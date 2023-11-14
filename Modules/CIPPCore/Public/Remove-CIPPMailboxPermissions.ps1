function Remove-CIPPMailboxPermissions {
    [CmdletBinding()]
    param (
        $userid,
        $AccessUser,
        $TenantFilter,
        $PermissionsLevel,
        $APIName = "Manage Shared Mailbox Access",
        $ExecutingUser
    )

    try {
        if ($userid -eq "AllUsers") {
            $Mailboxes = New-ExoRequest -tenantid $QueueItem.TenantFilter -cmdlet "get-mailbox"
            foreach ($Mailbox in $Mailboxes) {
                Remove-CIPPMailboxPermissions -PermissionsLevel @("FullAccess", "SendAs", "SendOnBehalf") -userid $Mailbox.UserPrincipalName -AccessUser $QueueItem.User -TenantFilter $QueueItem.TenantFilter -APIName $APINAME -ExecutingUser $QueueItem.ExecutingUser
            }        
        }
        else {
            $Results = $PermissionsLevel | ForEach-Object {
                switch ($_) {
                    "SendOnBehalf" {
                        $MailboxPerms = New-ExoRequest -Anchor $username -tenantid $Tenantfilter -cmdlet "Set-Mailbox" -cmdParams @{Identity = $userid; GrantSendonBehalfTo = @{'@odata.type' = '#Exchange.GenericHashTable'; remove = $AccessUser }; }
                        Write-LogMessage -user $ExecutingUser -API $APIName -message "Removed SendOnBehalf permissions for $($AccessUser) from $($userid)'s mailbox." -Sev "Info" -tenant $TenantFilter
                        "Removed SendOnBehalf permissions for $($AccessUser) from $($userid)'s mailbox." 
                    }
                    "SendAS" {
                        $MailboxPerms = New-ExoRequest -Anchor $username -tenantid $Tenantfilter -cmdlet "Remove-RecipientPermission" -cmdParams @{Identity = $userid; Trustee = $AccessUser; accessRights = @("SendAs") }
                        Write-LogMessage -user $ExecutingUser -API $APIName -message "Removed SendAs permissions for $($AccessUser) from $($userid)'s mailbox." -Sev "Info" -tenant $TenantFilter
                        "Removed SendAs permissions for $($AccessUser) from $($userid)'s mailbox."
                    }
                    "FullAccess" {
                        $permissions = New-ExoRequest -tenantid $TenantFilter -cmdlet "Remove-MailboxPermission" -cmdParams @{Identity = $userid; user = $AccessUser; accessRights = @("FullAccess") } -Anchor $userid
                        Write-LogMessage -user $ExecutingUser -API $APIName -message  "Removed FullAccess permissions for $($AccessUser) from $($userid)'s mailbox." -Sev "Info" -tenant $TenantFilter
                        "Removed FullAccess permissions for $($AccessUser) from $($userid)'s mailbox."
                    }
                }
            }
        }
        return $Results
    }
    catch {
        Write-LogMessage -user $ExecutingUser -API $APIName -message  "Could not remove mailbox permissions for $($userid). Error: $($_.Exception.Message)" -Sev "Error" -tenant $TenantFilter
        return "Could not remove mailbox permissions for $($userid). Error: $($_.Exception.Message)"
    }
}
