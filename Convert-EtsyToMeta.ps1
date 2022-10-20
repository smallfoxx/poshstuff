[CmdletBinding()]
param(
    [parameter(ValueFromPipeline,ValueFromPipelineByPropertyName)]
    [string]$EtsyFile="$env:USERPROFILE\Downloads\EtsyListingsDownload.csv",
    [string]$MetaFile="$env:USERPROFILE\Downloads\catalog_products-FromEtsy.csv",
    [string]$CompanyName="NalinuPink",
    [string]$DefaultCategory="",
    [switch]$AppendToMeta
    )
Begin {
    #Meta field on the left to populate from Etsy field on the right
    $Mapping = [ordered]@{
<#    Etsy fields
        TITLE
        DESCRIPTION
        PRICE
        CURRENCY_CODE
        QUANTITY
        TAGS
        MATERIALS
        IMAGE1
#>
        $id='([GUID]::NewGuid()).Guid'
        title='$entry.TITLE'
        description='$entry.DESCRIPTION'
        availability='if ($entry.QUANTITY -gt 0) { "in stock" } else { "out of stock" }'
        condition='"new"'
        price='"{0:0.00} {1}" -f [double]($entry.PRICE),$entry.CURRENCY_CODE'
        link='$entry.IMAGE1'
        image_link='$entry.IMAGE1'
        brand='$CompanyName'
        google_product_category='$DefaultCategory'
        fb_product_category='$DefaultCategory'
        quantity_to_sell_on_facebook='$entry.QUANTITY'
        sale_price=''
        sale_price_effective_date=''
        item_group_id=''
        gender=''
        color=''
        size=''
        age_group=''
        material=''
        pattern=''
        shipping=''
        shipping_weight=''
        commerce_tax_category=''
        'style[0]'=''
    }

    Function Translate-ObjToObj {
        [CmdletBinding()]
        param (
            # Parameter help description
            [Parameter(ValueFromPipeline)]
            $entry,
            $MappingTable = $Mapping
        )
        
        process {
            $result=[ordered]@{}
            ForEach ($key in $MappingTable.keys) {
                If ([string]::IsNullOrEmpty($Mapping.$Key)) {
                    $result.$key = ""
                } else {
                    $result.$key = Invoke-Expression $Mapping.$key
                }
            }
            $result
        }
    }
    
}

Process {
    try {
        $EtsyListings = Import-Csv $EtsyFile
        $EtsyListings | Translate-ObjToObj | Export-Csv -NoTypeInformation -Path $MetaFile -Append:$AppendToMeta
    } catch {
        Write-Error $Error[0]
    }
}