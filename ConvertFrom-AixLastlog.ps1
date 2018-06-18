
<#PSScriptInfo

.VERSION 1.0

.GUID 00321f7e-d821-4ad4-a481-dae85e6f4990

.AUTHOR David Zampino

.COMPANYNAME 

.COPYRIGHT 

.TAGS powershell aix

.LICENSEURI https://github.com/dzampino/ConvertFrom-AixLastLog/blob/master/LICENSE

.PROJECTURI https://github.com/dzampino/ConvertFrom-AixLastLog

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

<#
.SYNOPSIS
Converts an AIX lastlog file into a exportable PowerShell object

.DESCRIPTION
The AIX /etc/security/lastlog contains the list of users and last logon dates. Unfortunately, the file is not 
in a format that can easily be worked with. In addition, the timestamps are in UTC time and must be converted.

.PARAMETER InputObject
The lastlog file or file contents

.EXAMPLE
$lastlog = .\ConvertFrom-AixLastlog.ps1 -InputObject .\lastlog

.EXAMPLE
Get-ChildItem -Path $env:TEMP\lastlog | .\ConvertFrom-AixLastlog.ps1 | ConvertTo-Json | OutFile .\lastlog.json

#>
    
[CmdletBinding(HelpUri = 'https://github.com/dzampino/ConvertFrom-AixLastLog')]
param
(
    [Parameter(Mandatory = $true,
               ValueFromPipeline=$true)]
    [string]$InputObject
)

BEGIN
{
    Set-StrictMode -Version Latest       

    # Set $Username, otherwise it will throw an error for not being set
    $Username = $null
}

PROCESS 
{
    $File = Get-Content -Path $InputObject

    foreach ($Line in $File)
    {
        try 
        {
            # Check to see if line is a comment; will throw a terminating error if solely a newline
            if ($Line[0] -eq '*') {Continue}
            else
            {
                # Test for username
                if ($Line -match ':')
                {
                    $Username = $Line -replace ':',''
                    Continue
                }

                if ($Line -match 'time_last_login')
                {
                    [regex]$RegexTimeLastLogin = '(?<=time_last_login = ).+'
                    $TimeLastLogin = ($RegexTimeLastLogin.Matches($Line)).Value
                    $TimeLastLogin = $TimeLastLogin.Trim()
                    Continue
                }

                if ($Line -match 'time_last_unsuccessful_login')
                {
                    [regex]$RegexTimeLastUnsuccessfulLogin = '(?<=time_last_unsuccessful_login = ).+'
                    $TimeLastUnsuccessfulLogin = ($RegexTimeLastUnsuccessfulLogin.Matches($Line)).Value
                    $TimeLastUnsuccessfulLogin = $TimeLastUnsuccessfulLogin.Trim()
                    Continue
                }

                if ($Line -match 'tty_last_login')
                {
                    [regex]$RegexTtyLastLogin = '(?<=tty_last_login = ).+'
                    $TtyLastLogin = ($RegexTtyLastLogin.Matches($Line)).Value
                    $TtyLastLogin = $TtyLastLogin.Trim()
                    Continue
                }

                if ($Line -match 'tty_last_unsuccessful_login')
                {
                    [regex]$RegexTtyLastUnsuccessfulLogin = '(?<=tty_last_unsuccessful_login = ).+'
                    $TtyLastUnsuccessfulLogin = ($RegexTtyLastUnsuccessfulLogin.Matches($Line)).Value
                    $TtyLastUnsuccessfulLogin = $TtyLastUnsuccessfulLogin.Trim()
                    Continue
                }

                if ($Line -match 'host_last_login')
                {
                    [regex]$RegexHostLastLogin = '(?<=host_last_login = ).+'
                    $HostLastLogin= ($RegexHostLastLogin.Matches($Line)).Value
                    $HostLastLogin = $HostLastLogin.Trim()
                    Continue
                }

                if ($Line -match 'host_last_unsuccessful_login')
                {
                    [regex]$RegexHostLastUnsuccessfulLogin = '(?<=host_last_unsuccessful_login = ).+'
                    $HostLastUnsuccessfulLogin= ($RegexHostLastUnsuccessfulLogin.Matches($Line)).Value
                    $HostLastUnsuccessfulLogin = $HostLastUnsuccessfulLogin.Trim()
                    Continue
                }

                if ($Line -match 'unsuccessful_login_count')
                {
                    [regex]$RegexUnsuccessfulLoginCount = '(?<=unsuccessful_login_count = ).+'
                    $UnsuccessfulLoginCount= ($RegexUnsuccessfulLoginCount.Matches($Line)).Value
                    $UnsuccessfulLoginCount = $UnsuccessfulLoginCount.Trim()
                    Continue
                }
            }  
        }
        catch [System.IndexOutOfRangeException]
        {
            # Skip the first new line it comes across
            if (-not $Username) {Continue}

            $NewUserArgs = @{
                username                     = $Username
                time_last_login              = $TimeLastLogin
                time_last_unsuccessful_login = $TimeLastUnsuccessfulLogin
                tty_last_login               = $TtyLastLogin
                tty_last_unsuccessful_login  = $TtyLastUnsuccessfulLogin
                host_last_login              = $HostLastLogin
                host_last_unsuccessful_login = $HostLastUnsuccessfulLogin
                unsuccessful_login_count     = $UnsuccessfulLoginCount
            }

            $Result = New-Object -TypeName PSObject -Property $NewUserArgs
            
            Write-Output $Result

            # Clear all variables
            $Username = $null
            $TimeLastLogin = $null
            $TimeLastUnsuccessfulLogin = $null
            $TtyLastLogin = $null
            $TtyLastUnsuccessfulLogin = $null
            $HostLastLogin = $null
            $HostLastUnsuccessfulLogin = $null
            $UnsuccessfulLoginCount = $null
        }
        catch 
        {
            Write-Error $error[0]
            Break    
        }
    }    
}

END {}