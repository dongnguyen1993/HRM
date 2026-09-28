$devConn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;")
$pubConn = New-Object System.Data.SqlClient.SqlConnection("Server=localhost,14333;Database=HRM_Enterprise_DB;User Id=sa;Password=Sa@123456;TrustServerCertificate=True;")

$devConn.Open()
$pubConn.Open()

# 1. Sync CommonCodes from Dev to Pub
$cmdDev = $devConn.CreateCommand()
$cmdDev.CommandText = "SELECT GroupCode, Code, CodeName, SortOrder, IsActive, Description FROM CommonCodes"
$r = $cmdDev.ExecuteReader()

$cmdPub = $pubConn.CreateCommand()
$items = @()
while ($r.Read()) {
  $desc = if ($r.IsDBNull(5)) { $null } else { $r.GetString(5) }
  $items += [PSCustomObject]@{
    GroupCode = $r.GetString(0)
    Code = $r.GetString(1)
    CodeName = $r.GetString(2)
    SortOrder = $r.GetInt32(3)
    IsActive = $r.GetBoolean(4)
    Description = $desc
  }
}
$r.Close()

foreach ($item in $items) {
  $cmdPub.CommandText = @"
IF NOT EXISTS (SELECT 1 FROM CommonCodes WHERE GroupCode = @GroupCode AND Code = @Code)
BEGIN
    INSERT INTO CommonCodes (GroupCode, Code, CodeName, SortOrder, IsActive, Description)
    VALUES (@GroupCode, @Code, @CodeName, @SortOrder, @IsActive, @Description)
END
ELSE
BEGIN
    UPDATE CommonCodes
    SET CodeName = @CodeName, SortOrder = @SortOrder, IsActive = @IsActive, Description = @Description
    WHERE GroupCode = @GroupCode AND Code = @Code
END
"@
  $cmdPub.Parameters.Clear()
  $cmdPub.Parameters.AddWithValue("@GroupCode", $item.GroupCode) | Out-Null
  $cmdPub.Parameters.AddWithValue("@Code", $item.Code) | Out-Null
  $cmdPub.Parameters.AddWithValue("@CodeName", $item.CodeName) | Out-Null
  $cmdPub.Parameters.AddWithValue("@SortOrder", [int]$item.SortOrder) | Out-Null
  $cmdPub.Parameters.AddWithValue("@IsActive", [bool]$item.IsActive) | Out-Null
  $descVal = if ($item.Description) { $item.Description } else { [DBNull]::Value }
  $cmdPub.Parameters.AddWithValue("@Description", $descVal) | Out-Null
  $cmdPub.ExecuteNonQuery() | Out-Null
}

Write-Host "CommonCodes synced to Public DB!" -ForegroundColor Green

# 2. Check Area column in Users on Pub
$cmdPub.CommandText = @"
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'Area')
BEGIN
    ALTER TABLE Users ADD Area NVARCHAR(250) NULL;
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Users' AND COLUMN_NAME = 'MustChangePassword')
BEGIN
    ALTER TABLE Users ADD MustChangePassword BIT NOT NULL DEFAULT 0;
END
"@
$cmdPub.Parameters.Clear()
$cmdPub.ExecuteNonQuery() | Out-Null
Write-Host "Users table columns checked/updated on Public DB!" -ForegroundColor Green

$devConn.Close()
$pubConn.Close()
