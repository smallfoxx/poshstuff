<#PSScriptInfo

.VERSION 
    1.0.0.1

.GUID 
    cbd7128c-717b-4644-aab2-8617d00e5359

.AUTHOR 
    SmallFoxx

.COMPANYNAME 
    SmallFoxx

.COPYRIGHT 
    The MIT License (MIT)

.TAGS 
    Random Weighted Integer List

.LICENSEURI 
    https://opensource.org/licenses/MIT

.PROJECTURI
    https://github.com/smallfoxx/poshstuff/blob/main/Get-RandomWeighted.ps1

.RELEASENOTES

#>

<#
.SYNOPSIS
Return a random result from weigthed values
.DESCRIPTION
Utilizing a key-value pair hashtable, the script will return a random
result.  In the hashtable, the keys need to be the entries you are looking
randomize and their weights are the value of the pair.
.PARAMETER TableWeight
Key-value pair hashtable where the keys are the entries to be randomized
and the values are their respective weights. These weigthed values must
be integers unless the -Deeper switched is used. If the -Deeper switch
is utilized, any decimal based numerical value can be used for the weight.
.PARAMETER Iterations
The number of times to pull a random entry.
.PARAMETER Deeper
When used, the process will assign a specific range based on their
respective weights with a more accuracy.
.EXAMPLE
PS>$Colors = @{ "Red" = 5; "Blue" = 3; "Green" = 2}
PS>Get-RandomWeighted -TableWeight $Colors

Result will be a random color from Red, Blue, or Green.  The results
should be 'Red' about 50% of the time, 'Blue' about 30%, and 'Green'
about 20%.
.EXAMPLE
PS>$Bob = Get-ADUser -Identity "BobSmith"
PS>$Chris = Get-AdUser -Identity "ChrisFields"
PS>$Debbie = Get-AdUser -Identity "DebbieReynolds"
PS>$Ecru = Get-AdUser -Identity "EcruTeam"
PS>$OnCallTable = @{
    $Bob = 0.0423
    $Chris = 0.5311
    $Debbie = 0.5284
    $Ecru = 0.3709
}
PS>Get-RandomWeighted -TableWeight $OnCallTable -Deeper

The Results will one of the 4 being picked based on weights. This means
'Bob' would be selected about 2.8%, 'Chris' about 36.1%, 'Debbie' about
35.9%, and 'Ecru' about 25.2%.
.EXAMPLE
PS>$Colors = @{ "Red" = 5; "Blue" = 3; "Green" = 2}
PS>Get-RandomWeighted -TableWeight $Colors -Iterations 10000 -Deeper | Group-Object | Select-Object -Property Name,Count
  
  Name  Count
  ----  -----
  Blue   2930
  Green  2002
  Red    5068

This ran through a deeper randomization of the 3 colors 10,000 times,
grouped the results, and displayed the names and counts of each result. 
Due to the nature of randomization, those counts will vary on each run
but should be close to 30%, 20%, and 50% for Blue, Green, and Red
respectively.

.LINK
Get-Random
#>  
[CmdletBinding()]
param(
    [hashtable]$TableWeight,
    [int64]$Iterations=1,
    [switch]$Deeper
)

begin {
    Function New-Range {
        param(
            [parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
            $Value,
            [parameter(ValueFromPipelineByPropertyName)]
            [decimal]$Weight=1
        )
        $PrevMaxRange = Get-MaxRange
        [PSCustomObject]@{
            "Value"=$Value
            "Weight"=$Weight
            "MinRange"=$PrevMaxRange
            "MaxRange"=$PrevMaxRange+$Weight
        }
    }
    Function Get-MaxRange {
        param(
            $RangeList = $script:ranges
        )
        [decimal](($RangeList | Measure-Object -Property MaxRange -Maximum).Maximum)
    }
    Function Get-WeightedResult {
        $WeightedResult = Get-Random -Minimum ([decimal]0) -Maximum (Get-MaxRange)
        $script:ranges | Where-Object {
            ($_.MinRange -lt $WeightedResult) -and ($_.MaxRange -ge $WeightedResult)
        }
    }
    Function Add-WeightToRange {
        param(
            $Value,
            [decimal]$Weight=1
        )
        If (-not $script:ranges) {
            $script:ranges = [System.Collections.ArrayList]@()
        }
        $ThisRange = New-Range -Value ($Value) -Weight ($Weight)
        $Null = $script:ranges.Add($ThisRange)
    }
}

process {
    If ($deeper) {
        ForEach ($key in $TableWeight.Keys) {
            Add-WeightToRange -Value $Key -Weight ($TableWeight.$Key)
        }
        1..$Iterations | ForEach-Object {
            $ResultEntry = Get-WeightedResult
            $ResultEntry.Value
        }
    } else {
        $array = [System.Collections.ArrayList]@()
        ForEach ($key in $TableWeight.Keys) {
            $null = 1..([int64]($TableWeight.$key)) | ForEach-Object { $array.Add($key) }
        }
        1..$Iterations | ForEach-Object {
            $array | Get-Random
        }
    } 
}

