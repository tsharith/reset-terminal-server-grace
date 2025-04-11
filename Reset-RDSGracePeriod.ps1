<#
.SYNOPSIS
    Script to query remaining RDS Grace Period days and reset it to default (120 Days).
    
.DESCRIPTION
    This script displays the remaining days of the RDS grace period and resets the grace period
    by taking ownership of the registry key and deleting it.

.NOTES
    Author: Harith
    Date: April 2025
    Disclaimer: Test thoroughly in a non-production environment. Use at your own risk.
#>

Clear-Host
$ErrorActionPreference = "SilentlyContinue"

function Get-RDSGracePeriodDays {
    $setting = Get-WmiObject -Namespace "root\cimv2\terminalservices" -Class "Win32_TerminalServiceSetting"
    $grace = Invoke-WmiMethod -Path $setting.__PATH -Name "GetGracePeriodDays"
    return $grace.daysleft
}

function Display-GracePeriodStatus ($daysLeft, $color = "Green") {
    Write-Host -ForegroundColor $color ("=" * 70)
    Write-Host -ForegroundColor $color "Terminal Server (RDS) grace period Days remaining are: $daysLeft"
    Write-Host -ForegroundColor $color ("=" * 70)
    Write-Host
}

function Enable-SeTakeOwnershipPrivilege {
    $ntCode = @"
using System;
using System.Runtime.InteropServices;
namespace Win32Api {
    public class NtDll {
        [DllImport("ntdll.dll", EntryPoint="RtlAdjustPrivilege")]
        public static extern int RtlAdjustPrivilege(ulong Privilege, bool Enable, bool CurrentThread, ref bool Enabled);
    }
}
"@
    Add-Type -TypeDefinition $ntCode -PassThru | Out-Null
    $enabled = $false
    [Win32Api.NtDll]::RtlAdjustPrivilege(9, $true, $false, [ref]$enabled) | Out-Null
}

function Reset-RDSGracePeriod {
    Enable-SeTakeOwnershipPrivilege

    $keyPath = "SYSTEM\CurrentControlSet\Control\Terminal Server\RCM\GracePeriod"
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($keyPath, 
        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
        [System.Security.AccessControl.RegistryRights]::TakeOwnership)

    $acl = $key.GetAccessControl()
    $acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
    $key.SetAccessControl($acl)

    $rule = New-Object System.Security.AccessControl.RegistryAccessRule(
        "Administrators", "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)

    Remove-Item -Path "HKLM:\$keyPath" -Force
}

# Display current grace period days
$currentDays = Get-RDSGracePeriodDays
Display-GracePeriodStatus -daysLeft $currentDays

# Reset grace period
Write-Host -ForegroundColor Red "Resetting Grace Period... Please Wait."
Reset-RDSGracePeriod
Start-Sleep -Seconds 10

# Re-check grace period (may require reboot or tlsbln.exe to update)
tlsbln.exe  # External tool assumed to update state
$updatedDays = Get-RDSGracePeriodDays
Display-GracePeriodStatus -daysLeft $updatedDays -color "Yellow"

# Clean up variables
Remove-Variable * -ErrorAction SilentlyContinue

Pause
