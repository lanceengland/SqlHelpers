# SqlHelpers
This repo is for PowerShell cmdlets to generate T-SQL code. There are a few T-SQL commands with tricky syntax that become cumbersome to repeatedly write. 

Though the MERGE statement has caveats in it's usage, documented [in this blog post](https://www.mssqltips.com/sqlservertip/3074/use-caution-with-sql-servers-merge-statement/) by Aaron Bertrand, under the right circumstances I find it a very useful tool.

For now, the MERGE cmdlet is a plain ps1 file. If I add another function, I will turn it into a module.

I hope you find this useful.
