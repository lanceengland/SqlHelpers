function Get-SQLMergeStatement {
    param
    (
        [Parameter( Mandatory=$True,
                    ValueFromPipeline=$False,
                    ValueFromPipelineByPropertyName=$False,
                    HelpMessage='Name of table to MERGE into')]
        [string] $TargetTableName,

        [Parameter( Mandatory=$True,
                    ValueFromPipeline=$False,
                    ValueFromPipelineByPropertyName=$False,
                    HelpMessage='Comma-separated list of columns to merge')]
        [string[]] $MergeColumns,

        [Parameter( Mandatory=$True,
                    ValueFromPipeline=$False,
                    ValueFromPipelineByPropertyName=$False,
                    HelpMessage='Comma-separated list of columns to JOIN on')]
        [string[]] $JoinColumns,
        
        [switch]$IncludeDeleteClause
    )
$MergeTemplate = @"
WITH SRC AS 
( 
    /* your source query here */ 
)
MERGE INTO $TargetTableName WITH (HOLDLOCK) AS TGT
    USING SRC ON ($(($JoinColumns |ForEach-Object { "SRC.$_ = TGT.$_" }) -join " AND`n"))

WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        $($MergeColumns -join ",`n`t`t"
    )
    VALUES (
        $(($MergeColumns |ForEach-Object { "SRC.$_" }) -join ",`n`t`t")
    )

WHEN MATCHED AND EXISTS (
    SELECT $(($MergeColumns |Where-Object { $JoinColumns -notcontains $_ } |ForEach-Object { "SRC.$_" }) -join ", ") 
    EXCEPT 
    SELECT $(($MergeColumns |Where-Object { $JoinColumns -notcontains $_ } |ForEach-Object { "TGT.$_" }) -join ", ")
    ) 
THEN
    UPDATE SET 
    $(($MergeColumns |Where-Object { $JoinColumns -notcontains $_ } |ForEach-Object { "$_ = SRC.$_" }) -join ",`n`t")
$(if($IncludeDeleteClause) {"`nWHEN NOT MATCHED BY SOURCE THEN DELETE /* Use with caution! This will delete anything in the target table not found in the source query. */"})
;
"@
    Write-Output $MergeTemplate
}

Clear-Host
Get-SQLMergeStatement -TargetTableName dbo.ServiceRemarkCode -JoinColumns ImportKey, CodeListQualifierCode -MergeColumns ServicePaymentId,BtsInterchangeId,ImportKey,CodeListQualifierCode,RemarkCode -IncludeDeleteClause
