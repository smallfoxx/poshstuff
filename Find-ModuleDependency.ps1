<#PSScriptInfo

.VERSION
    0.1.0.22101

.GUID
    334a9b68-0f6b-4836-9ad5-15163d4fb908

.AUTHOR
    SMFX

.COMPANYNAME 
    SmallFoxx

.COPYRIGHT 
    The MIT License (MIT)

.TAGS 
    Commands Dependencies Module Dependency

.LICENSEURI 
    https://opensource.org/licenses/MIT

.PROJECTURI
    https://github.com/smallfoxx/poshstuff/blob/main/Find-Moduledependency.ps1

.RELEASENOTES

#>

<#
.SYNOPSIS
Find all modules a particular set of script files use
.DESCRIPTION
  By searching through content of files in path, finds all the commands in those files, and the modules that house those commands.
.PARAMETER Path
Location of directory or files to search
.PARAMETER Filter
Filter of files to include in the search
.PARAMETER Exclude
Exclusionary filter of files to not include in search
.PARAMETER Recurse
If Path is a directory, it will search down through its subdirectories.

.EXAMPLE
Find-Moduledependency

ModuleType Version  PreRelease Name                          ExportedCommands
---------- -------  ---------- ----                          ----------------
Manifest   7.0.0.0             Microsoft.PowerShell.Utility  {Add-Member, Add...

This will search through all .PS1 & .PSM1 files in the current directory and 
find the modules used.

.EXAMPLE
$Modules = Find-Moduledependency -Path C:\Test
PS>$Modules.UsedCommands

CommandType     Name        Version    Source
-----------     ----        -------    ------
Cmdlet          Write-Host  7.0.0.0    Microsoft.PowerShell.Utility

After searching all .PS1 & .PSM1 files in the C:\Test directory, the
UsedCommands properties of each module will list the commands found
in the files

.EXAMPLE
$Modules = Find-Moduledependency -Path C:\Test -Recurse
PS>$Modules.UsedCommands.FoundUses

Command       File                      Line Character
-------       ----                      ---- ---------
Write-Host    C:\test\example.psm1         2         4
Write-Host    C:\test\example.psm1         6         4
Get-ChildItem C:\test\stuff\folders.ps1    5         2

Looking in .PS1 & .PSM1 files in the C:\Test directory and the
subdirectories under it, the .FoundUses property lists the location in
each file a command found as listed in the .UsedCommands properties
of each module.

.LINK
Get-Command
Get-Module
Find-Command
#> 
[CmdletBinding()]
        [string]$Exclude="*.psd1",
        [switch]$Recurse
                [string]$Path,
                [string]$CommandMatch = "(^|=|\||\()\s*(?<comm>(?<verb>\w+)(\-(?<noun>\w+))?)[^=]+(;|$)"
            )
            $Content = Get-Content -path $path

            $l=0
param (
    [Parameter(ValueFromPipeline)]
    [string]$Path=".",
    [string]$Filter="*.ps?1",
    [string]$Exclude="*.psd1",
    [switch]$Recurse
)

begin {
    $excludeFunctions = @("NOT","Function","If","Param","ForEach","Begin","Process","End","Parameter","Mandatory","Switch")
    $FoundCommands = [System.Collections.ArrayList]@()
    $Modules = @{}
    Function Find-CommandInFile {
        param(
            [parameter(ValueFromPipeline)]
            [string]$Path,
            [string]$CommandMatch = "(^|=|\||\()\s*(?<comm>(?<verb>\w+)(\-(?<noun>\w+))?)[^=]+(;|$)"
        )
        $Content = Get-Content -path $path

        $l=0
        ForEach ($Line in $Content) {
            $l++
            ForEach ($matches in ([regex]::Matches($line,$CommandMatch))) {
                $commMatch = $matches.groups | Where-Object { $_.name -eq 'comm' }

                ForEach ($Entry in $commMatch) {

                    [PSCustomObject]@{
                        Command = $Entry.Value
                        File = $Path
                        Line = $l
                        Character = $Entry.Index
                    }
                }
            }
        }
    }
}

process {
    $FilesInPath = Get-ChildItem -Path $Path -Filter $Filter -Exclude $Exclude -Recurse:$Recurse
    ForEach ($File in $FilesInPath) {
        $FoundEntries = Find-CommandInFile -Path $File

        $null = $FoundEntries | ForEach-Object { $FoundCommands.Add($_) }
    }
}

end {
    $CommandGroups = $FoundCommands | Group-Object -Property Command
    ForEach ($Group in $CommandGroups) {
        If (-not [string]::IsNullOrEmpty($Group.Name) -and ($excludeFunctions -notcontains $Group.Name)) {
            $Command = Get-Command $Group.Name -ErrorAction SilentlyContinue
            If ($Command.Module) {
                $Command | Add-Member NoteProperty FoundUses ($Group.Group) -Force
                $Modules.($Command.Module) += @($Command)
            }
        }
    }
    ForEach ($ModuleEntry in $Modules.Keys) {
        $ModuleEntry | Add-member NoteProperty UsedCommands ($Modules.$ModuleEntry) -Force
        $ModuleEntry
    }
}