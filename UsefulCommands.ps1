
<#
.SYNOPSIS
Quick, useful commands to use for various purposes
.DESCRIPTION
A list of commands to work for various tasks to be used with PowerShell that can often be used to send to end users.
.NOTES
Common fields are PURPOSE, COMMAND, PLATFORM, AUDIENCE
#>

$commandTable = [ordered]@{
    "GetIPAddress" = [ordered]@{
        "Purpose"="Get a user's IP addresses and wait"
        "Command"=@"
powershell -command "& { ipconfig /all | %{ if ($_ -match 'v4.+\D((\d+\.){3}\d+)') { $matches[1] } }; (iwr 'ident.me').content; pause }"
"@
        "Platform"="Run"
        "Audience"="Users"
    }
}

Function GetIPAddress {
<#
This is a quick command that can be run from a Command Prompt or the Run box of 
#>
    param([switch]$NoWait)
    switch ($NoWait) {
        $true {}
        default {
            @"
powershell.exe -command "& { ipconfig /all | %{ if (`$_ -match 'v4.+\D((\d+\.){3}\d+)') { `$matches[1] } }; (iwr 'ident.me').content; `$Null=Read-Host '^^IP(s) above^^' }"
"@
        }
    }
}