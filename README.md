# ConvertFrom-AixLastlog
A PowerShell script that imports an AIX lastlog file and converts it into a PowerShell object

## Why?
The AIX lastlog file, which can be found at /etc/security/lastlog is in a non-standard format that can't be used without conversion. In addition, the timestamps are presented in Unix time and must be converted. Using this script, you can easily convert to other formats, such as JSON or CSV. You are also easily able iterate through it and convert the Unix timestamps.

## Examples

### Set a variable with the imported file
`$lastlog = .\ConvertFrom-AixLastlog.ps1 -InputObject .\lastlog`

### Convert to JSON and save
`Get-ChildItem -Path $env:TEMP\lastlog | .\ConvertFrom-AixLastlog.ps1 | ConvertTo-Json | OutFile .\lastlog.json`

## To-do
* Convert project to a module
* Add Unix time conversion function