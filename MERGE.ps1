function Get-SQLMergeStatement {
    <#
        .SYNOPSIS
            Generates and returns T-SQL MERGE statement.

        .DESCRIPTION
            Generates and returns T-SQL MERGE statement based on parameter values. 
            
        .LINK
            https://docs.microsoft.com/en-us/sql/t-sql/statements/merge-transact-sql

        .PARAMETER TargetTableName
            The name of the table to merge data into.

        .PARAMETER MergeColumns
            An array of column name(s) to be merged.

        .PARAMETER JoinColumns
            An array of column name(s) to join on i.e. specifies the conditions on which the source table is joined with the target table to determine if they match.
            
        .PARAMETER IncludeDeleteClause
            When this switch is enabled, the DELETE clause of the MERGE statement is included. Default is not included.


        .NOTES
            Author: Lance England
            Blog: http://lance-england.com

        .EXAMPLE
            Get-SQLMergeStatement -TargetTableName Tbl -JoinColumns a -MergeColumns a,b,c

            Merges columns a, b, c into Tbl ON column a

        .EXAMPLE
            Get-SQLMergeStatement -TargetTableName Tbl -JoinColumns a, b -MergeColumns a,b,c,d

            Merges columns a, b, c, d into Tbl ON columns a and b
        
        .EXAMPLE
            Get-SQLMergeStatement -TargetTableName Tbl -JoinColumns a, b -MergeColumns a,b,c,d -IncludeDeleteClause

            Merges columns a, b, c, d into Tbl ON columns a and b. Includes the DELETE clause.
    #>
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
    USING SRC ON ($(($JoinColumns |ForEach-Object { "SRC.$_ = TGT.$_" }) -join " AND "))

WHEN NOT MATCHED BY TARGET THEN
    INSERT (
        $($MergeColumns -join ",`n        ")
    )
    VALUES (
        $(($MergeColumns |ForEach-Object { "SRC.$_" }) -join ",`n        ")
    )

WHEN MATCHED AND EXISTS (
    SELECT $(($MergeColumns |Where-Object { $JoinColumns -notcontains $_ } |ForEach-Object { "SRC.$_" }) -join ", ") 
    EXCEPT 
    SELECT $(($MergeColumns |Where-Object { $JoinColumns -notcontains $_ } |ForEach-Object { "TGT.$_" }) -join ", ")
    ) 
THEN
    UPDATE SET 
    $(($MergeColumns |Where-Object { $JoinColumns -notcontains $_ } |ForEach-Object { "$_ = SRC.$_" }) -join ",`n    ")
$(if($IncludeDeleteClause) {"`nWHEN NOT MATCHED BY SOURCE THEN DELETE /* Use with caution! This will delete anything in the target table not found in the source query. */"})
;
"@

    Write-Output $MergeTemplate
}
