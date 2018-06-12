<#
.SYNOPSIS
    Converts an AIX lastlog file into a exportable PowerShell object
.DESCRIPTION
    The AIX /etc/security/lastlog contains the list of users and last logon dates. Unfortunately, the file is not 
    in a format that can easily be worked with. In addition, the timestamps are in UTC time and must be converted.
.NOTES
    Author: David Zampino
    Date created: 2018-06-05
#>
    
[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $true)]
    $Path
)

Set-StrictMode -Version Latest
function New-User
{
    New-Object -TypeName PSObject -Property @{
        username                     = $Username
        time_last_login              = $TimeLastLogin
        time_last_unsuccessful_login = $TimeLastUnsuccessfulLogin
        tty_last_login               = $TtyLastLogin
        tty_last_unsuccessful_login  = $TtyLastUnsuccessfulLogin
        host_last_login              = $HostLastLogin
        host_last_unsuccessful_login = $HostLastUnsuccessfulLogin
        unsuccessful_login_count     = $UnsuccessfulLoginCount
    }
}

$Username = $null
$TimeLastLogin = $null
$TimeLastUnsuccessfulLogin = $null
$TtyLastLogin = $null
$TtyLastUnsuccessfulLogin = $null
$HostLastLogin = $null
$HostLastUnsuccessfulLogin = $null
$UnsuccessfulLoginCount = $null

$File = Get-Content -Path $Path
$LineNumber = 0 

foreach ($Line in $File)
{
    $LineNumber++
    Write-Verbose "Current line ($LineNumber): $Line"
    try 
    {
        # Check to see if line is a comment; will throw a terminating error if solely a newline
        if ($Line[0] -eq '*') {Continue}
        else
        {
            # Test for username
            if ($Line -match ':')
            {
                Write-Verbose 'Username found'
                $Username = $Line -replace ':',''
                Continue
            }
            # Test for time of last login
            if ($Line -match 'time_last_login')
            {
                Write-Verbose 'time_last_login found'
                [regex]$RegexTimeLastLogin = '(?<=time_last_login = ).+'
                $TimeLastLogin = ($RegexTimeLastLogin.Matches($Line)).Value
                $TimeLastLogin = $TimeLastLogin.Trim()
                Continue
            }
            # Test for time of last unsuccessful login
            if ($Line -match 'time_last_unsuccessful_login')
            {
                Write-Verbose 'time_last_unsuccessful_login found'
                [regex]$RegexTimeLastUnsuccessfulLogin = '(?<=time_last_unsuccessful_login = ).+'
                $TimeLastUnsuccessfulLogin = ($RegexTimeLastUnsuccessfulLogin.Matches($Line)).Value
                $TimeLastUnsuccessfulLogin = $TimeLastUnsuccessfulLogin.Trim()
                Continue
            }
            # Test for terminal of last login
            if ($Line -match 'tty_last_login')
            {
                Write-Verbose 'tty_last_login found'
                [regex]$RegexTtyLastLogin = '(?<=tty_last_login = ).+'
                $TtyLastLogin = ($RegexTtyLastLogin.Matches($Line)).Value
                $TtyLastLogin = $TtyLastLogin.Trim()
                Continue
            }
            # Test for type of terminal for last unsuccessful
            if ($Line -match 'tty_last_unsuccessful_login')
            {
                Write-Verbose 'tty_last_unsuccessful_login found'
                [regex]$RegexTtyLastUnsuccessfulLogin = '(?<=tty_last_unsuccessful_login = ).+'
                $TtyLastUnsuccessfulLogin = ($RegexTtyLastUnsuccessfulLogin.Matches($Line)).Value
                $TtyLastUnsuccessfulLogin = $TtyLastUnsuccessfulLogin.Trim()
                Continue
            }
            # Test for IP address or hostname
            if ($Line -match 'host_last_login')
            {
                Write-Verbose 'host_last_login found'
                [regex]$RegexHostLastLogin = '(?<=host_last_login = ).+'
                $HostLastLogin= ($RegexHostLastLogin.Matches($Line)).Value
                $HostLastLogin = $HostLastLogin.Trim()
                Continue
            }
            # Test for IP address or hostname of last failed login
            if ($Line -match 'host_last_unsuccessful_login')
            {
                Write-Verbose 'host_last_unsuccessful_login found'
                [regex]$RegexHostLastUnsuccessfulLogin = '(?<=host_last_unsuccessful_login = ).+'
                $HostLastUnsuccessfulLogin= ($RegexHostLastUnsuccessfulLogin.Matches($Line)).Value
                $HostLastUnsuccessfulLogin = $HostLastUnsuccessfulLogin.Trim()
                Continue
            }
            # Test for IP address or hostname of last failed login
            if ($Line -match 'unsuccessful_login_count')
            {
                Write-Verbose 'unsuccessful_login_count found'
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
            Username                  = $Username
            TimeLastLogin             = $TimeLastLogin
            TimeLastUnsuccessfulLogin = $TimeLastUnsuccessfulLogin
            TtyLastLogin              = $TtyLastLogin
            TtyLastUnsuccessfulLogin  = $TtyLastUnsuccessfulLogin
            HostLastLogin             = $HostLastLogin
            HostLastUnsuccessfulLogin = $HostLastUnsuccessfulLogin
            UnsuccessfulLoginCount    = $UnsuccessfulLoginCount
        }

        New-User @NewUserArgs

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