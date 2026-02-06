# SQL Server Schema 匯出與文件產生教學

本文記錄如何從 SQL Server 取得資料庫 Schema，並整合其他資料來源產生 Markdown 格式的文件。

---

## 1. 使用 sqlcmd 取得 DB Schema

### 前置條件

- 安裝 SQL Server ODBC Driver 或 SQL Server 命令列工具
- 確認可以連線到目標資料庫

### 指令

```bash
sqlcmd -S <伺服器IP> -U <帳號> -P <密碼> -d <資料庫名稱> -Q "<SQL查詢>" -s"," -W
```

### 參數說明

| 參數 | 說明 |
|------|------|
| `-S` | 伺服器位址 |
| `-U` | 使用者帳號 |
| `-P` | 密碼 |
| `-d` | 資料庫名稱 |
| `-Q` | 要執行的 SQL 查詢 |
| `-s","` | 欄位分隔符號（逗號） |
| `-W` | 移除尾端空白 |
| `-o` | 輸出到檔案（可選） |

### 查詢所有資料表與欄位

```sql
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION
```

### 完整範例

```bash
sqlcmd -S 10.109.12.28 -U theone -P abcd -d Obts -Q "SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE FROM INFORMATION_SCHEMA.COLUMNS ORDER BY TABLE_NAME, ORDINAL_POSITION" -s"," -W -o schema.csv
```

### 輸出結果說明

| 欄位 | 說明 |
|------|------|
| TABLE_NAME | 資料表名稱 |
| COLUMN_NAME | 欄位名稱 |
| DATA_TYPE | 資料型別（varchar, int, decimal 等） |
| CHARACTER_MAXIMUM_LENGTH | 字串最大長度（-1 表示 MAX） |
| NUMERIC_PRECISION | 數值精度 |
| NUMERIC_SCALE | 小數位數 |

---

## 2. 使用 PowerShell 讀取 Excel xlsx 檔案

### 方法：使用 COM 物件

PowerShell 可以透過 Excel COM 物件來讀取 xlsx 檔案，不需要額外安裝套件。

### 腳本範例：匯出所有 Sheet 為 CSV

```powershell
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$excel.DisplayAlerts = $false
$workbook = $excel.Workbooks.Open("D:\path\to\file.xlsx")

$outputDir = "E:\output\xlsx-export"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

foreach ($sheet in $workbook.Sheets) {
    $sheetName = $sheet.Name -replace '[\\/:*?"<>|]', '_'
    $outputFile = Join-Path $outputDir "$sheetName.csv"

    $usedRange = $sheet.UsedRange
    $rows = $usedRange.Rows.Count
    $cols = $usedRange.Columns.Count

    $output = @()
    for ($r = 1; $r -le $rows; $r++) {
        $rowData = @()
        for ($c = 1; $c -le [Math]::Min($cols, 10); $c++) {
            $cellValue = $sheet.Cells.Item($r, $c).Text
            $cellValue = $cellValue -replace '"', '""'
            $rowData += "`"$cellValue`""
        }
        $output += ($rowData -join ",")
    }
    $output | Out-File -FilePath $outputFile -Encoding UTF8
    Write-Output "Exported: $sheetName"
}

$workbook.Close($false)
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
Write-Output "Done!"
```

### 注意事項

- 需要安裝 Microsoft Excel
- COM 物件操作較慢，大型檔案需要耐心等待
- 記得釋放 COM 物件避免 Excel 程序殘留

---

## 3. 使用 PowerShell 讀取匯出的 CSV

### 使用 Import-Csv

```powershell
$csvData = Import-Csv "path\to\file.csv" -Encoding UTF8

foreach ($row in $csvData) {
    # 存取欄位
    $value = $row.欄位名稱
}
```

### 處理中文欄位名稱的技巧

當腳本與 CSV 檔案編碼不一致時，中文比對可能失敗。解決方法是使用 Unicode 碼點：

```powershell
# 定義中文字串（使用 Unicode）
$namePattern = [char]0x540D + [char]0x7A31  # "名稱"
$descPattern = [char]0x8AAA + [char]0x660E  # "說明"
$typePattern = [char]0x578B + [char]0x614B  # "型態"

# 比對欄位名稱
foreach ($p in $row.PSObject.Properties) {
    if ($p.Name.Contains($namePattern)) {
        $colName = $p.Value
    }
    if ($p.Name.Contains($descPattern)) {
        $desc = $p.Value
    }
}
```

### 常用 Unicode 碼點查詢

| 中文 | Unicode |
|------|---------|
| 名 | 0x540D |
| 稱 | 0x7A31 |
| 說 | 0x8AAA |
| 明 | 0x660E |
| 型 | 0x578B |
| 態 | 0x614B |
| 欄 | 0x6B04 |
| 位 | 0x4F4D |

---

## 4. 整合資料產生 Markdown 文件

### 腳本架構

```powershell
# 1. 讀取 xlsx 說明資料
$xlsxInfo = @{}  # key: "TableName.ColumnName", value: @{desc, enumDef}

foreach ($file in Get-ChildItem "xlsx-export\*.csv") {
    $csvData = Import-Csv $file.FullName -Encoding UTF8
    foreach ($row in $csvData) {
        # 解析欄位名稱和說明
        $key = "$tableName.$colName"
        $xlsxInfo[$key] = @{ desc = $desc; enumDef = $enumDef }
    }
}

# 2. 讀取實際 DB Schema
$dbTables = [ordered]@{}

Get-Content "schema.csv" -Encoding UTF8 | ForEach-Object {
    # 解析每一行，建立資料結構
    $dbTables[$table] += @{ column = $column; type = $fullType }
}

# 3. 產生 Markdown（以 DB Schema 為主，xlsx 為輔）
$lines = @()
$lines += "# Database Schema"

foreach ($table in $dbTables.Keys) {
    $lines += "## $table"
    $lines += "| Column | Type | Description |"
    $lines += "|--------|------|-------------|"

    foreach ($col in $dbTables[$table]) {
        $key = "$table.$($col.column)"
        $desc = if ($xlsxInfo.ContainsKey($key)) { $xlsxInfo[$key].desc } else { "" }
        $lines += "| $($col.column) | $($col.type) | $desc |"
    }
}

$lines | Out-File -FilePath "output.md" -Encoding UTF8
```

### 處理特殊型別

```powershell
# 處理 nvarchar(-1) 顯示為 nvarchar(MAX)
if ($maxLen -eq "-1") {
    $fullType = "$dataType(MAX)"
} else {
    $fullType = "$dataType($maxLen)"
}
```

---

## 5. 完整腳本範例

完整腳本位於：`C:\Users\admin\generate_db_doc_final2.ps1`

### 執行方式

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\admin\generate_db_doc_final2.ps1"
```

---

## 6. 常見問題

### Q: sqlcmd 找不到？

安裝 SQL Server 命令列工具：
- 下載 Microsoft ODBC Driver for SQL Server
- 或安裝 SQL Server Management Studio (SSMS)

### Q: PowerShell 中文亂碼？

確保使用 UTF-8 編碼：
```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
```

### Q: Excel COM 物件執行後 Excel 程序殘留？

確保正確釋放 COM 物件：
```powershell
$workbook.Close($false)
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
```

### Q: -like 運算子對中文無效？

使用 Unicode 碼點或 `.Contains()` 方法比對。

---

## 7. 產出檔案

| 檔案 | 說明 |
|------|------|
| `db-schema.csv` | sqlcmd 匯出的原始 schema |
| `xlsx-export/*.csv` | Excel 各 sheet 匯出的 CSV（中間產物，可刪除） |
| `OBTS-Database-Schema.md` | 最終產生的 Markdown 文件 |
