<#
.SYNOPSIS
A quick script to test hash contains vs array -contains
.DESCRIPTION
Generates a script of objects using GUID's as unique values (SourceList), a Comparison List which has random GUID
values either in the SourceList or not, depending on the PercentInList value. If the SourceList is not a hash
table, it will build a hash table for comparison. Timings are then displayed for comparison.
.PARAMETER SourceListLength
Length of SourceList to generate
.PARAMETER PercentInList
When generating the CompareList, how many should be found in the SourceList by a percentage.
.PARAMETER CompareListLength
How long to make the CompareList. Defaults to a length to 
#>
[CmdletBinding(DefaultParameterSetName="Default")]
param([int]$SourceListLength=75,
    [double]$PercentInList=0.5,
    [int]$CompareListLength=[int]($SourceListLength*(1/$PercentInList)),
    [switch]$ExportHash,
    [parameter(Mandatory,ParameterSetName="BuildOnlyHash")]
    [switch]$HashOnly,
    [parameter(Mandatory,ParameterSetName="ImportHash")]
    [switch]$ImportHash,
    [string]$HashFile=".\hashfile.xml"
    )

Function NewEntry {
    param($GUID=[guid]::NewGuid())
    $Obj = @{ "GUID" = $GUID }
    $Obj.Label = "GUID - {0}" -f $Obj.GUID
    $Obj.Splits = $Obj.GUID -split '-'
    [PSCustomObject]$Obj
}

Function GenerateSource {
    param([int]$Length=$SourceListLength)

    If ($HashOnly) {
        $HashSource = @{}
    }
    1..($Length) | ForEach-Object {
        If ($HashOnly) {
            $GUID=[guid]::NewGuid()
            $HashSource.$GUID = NewEntry -GUID $GUID
        } else {
            NewEntry
        }
    }

    If ($HashOnly) {
        $HashSource
    }
}

Function GenerateCompare {
    param($SourceList=$srcList,
        [int]$Length=$CompareListLength,
        [double]$Percentage=$PercentInList
    )

    1..$Length | ForEach-Object {
        If ((Get-Random -Maximum ([double]1)) -lt $Percentage) {
            If ($HashOnly) {
                $SourceList.Values | Get-Random
            } else {
                $SourceList | Get-Random
            }
        } else {
            NewEntry
        }
    }
}

If ($PercentInList -gt 1) {
    If ($PercentInList -gt 100) {
        $PercentInList = $PercentInList / $SourceListLength
    } else {
        $PercentInList = $PercentInList / 100
    }
}

If ($ImportHash) {
    $HashOnly=$true
    Write-Host "Import Source Hashtable..."
    $SourceMeasure = Measure-Command { $script:SrcList = Import-Clixml $script:HashFile }
    Write-Host ("Imported in [{0} ms]" -f $SourceMeasure.TotalMilliseconds)
} else {
    Write-Host "Generating Source List..."
    $SourceMeasure = Measure-Command { $script:SrcList = GenerateSource }
    Write-Host ("Generated in [{0} ms]" -f $SourceMeasure.TotalMilliseconds)
}

Write-Host "Generating Compare List..."
$CompareMeasure = Measure-Command { $script:CmpList = GenerateCompare }
Write-Host ("Generated in [{0} ms]" -f $CompareMeasure.TotalMilliseconds)

Write-Host ""
Write-Host ""

If (-not $HashOnly) {
    Write-Host "Testing compare to list..."
    $TestingMeasure = Measure-Command { $script:FoundList = $script:CmpList | Where-Object { $_.GUID -in $script:SrcList.Guid } }
    Write-Host ("Performed in [{0} ms]" -f $TestingMeasure.TotalMilliseconds)

    Write-Host ""
}

Write-Host "Testing compare to hash..."
$FullHashMeasure = Measure-Command { 
    If ($HashOnly) {
        $script:hashlist=$SrcList
    } else {
        Write-Host "    Building hash table..."
        $HashBuildMeasure = Measure-Command { $script:Hashlist=@{}; $script:SrcList | ForEach-Object { $script:hashlist.($_.GUID) = $_ } }
        Write-Host ("    Performed in [{0} ms]" -f $HashBuildMeasure.TotalMilliseconds)
    }

    write-host "  Compare Length: $($script:CmpList.Length)"
    Write-Debug "Example: $(($script:CmpList | get-random).GUID)"

    $script:HashFoundList = $script:CmpList | Where-Object { $script:hashlist.ContainsKey($_.GUID) } 
}
Write-Host ("Performed in [{0} ms]" -f $FullHashMeasure.TotalMilliseconds)

If ($ExportHash) {
    Write-Host ""
    Write-Host ""
    Write-Host "Exporting Source Hashtable..."
    $ExportMeasure = Measure-Command { $script:HashList | Export-Clixml $script:HashFile }
    Write-Host ("Exported in [{0} ms]" -f $ExportMeasure.TotalMilliseconds)
}
