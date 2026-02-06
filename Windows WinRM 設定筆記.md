# Windows WinRM (PowerShell Remoting) 設定筆記

## 概述

WinRM (Windows Remote Management) 讓你可以從另一台電腦遠端執行 PowerShell 指令，適合 CLI 操作、自動化腳本、遠端管理。

---

## 快速設定步驟

### 1. 以系統管理員身分開啟 PowerShell

### 2. 確認網路設定為「私人」

```powershell
# 檢查目前網路類型
Get-NetConnectionProfile
```

如果 `NetworkCategory` 是 `Public`，需要改成 `Private`：

```powershell
# 改成私人網路（Ethernet 換成你的網路介面名稱，如 Wi-Fi）
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
```

### 3. 啟用 PS Remoting

```powershell
Enable-PSRemoting -Force
```

### 4. 驗證是否成功

```powershell
Test-WSMan localhost
```

有回傳資訊（不是錯誤）就代表成功。

---

## 從另一台電腦連線

### 互動式 Session

```powershell
Enter-PSSession -ComputerName <目標電腦名稱或IP> -Credential (Get-Credential)
```

### 執行單一指令

```powershell
Invoke-Command -ComputerName <目標電腦名稱或IP> -Credential (Get-Credential) -ScriptBlock {
    Get-Process
}
```

---

## 遇到的問題與解決方案

### 問題 1：公用網路導致防火牆阻擋

**錯誤訊息：**
> 因為此電腦上的其中一個網路連線類型設定為 [公用]，所以 WinRM 防火牆例外無法作用

**原因：**
Windows 對網路分三種 Profile：
- Public（公用）→ 最嚴格，預設封鎖 WinRM
- Private（私人）→ 允許 WinRM
- Domain（網域）→ 允許 WinRM

**解決方案：**
把網路改成「私人」：

```powershell
Set-NetConnectionProfile -InterfaceAlias "Ethernet" -NetworkCategory Private
```

或透過 GUI：設定 → 網路和網際網路 → 點選目前連線 → 網路設定檔 → 私人

---

### 問題 2：WinRM 沒有 TTY（重要限制）

**現象：**
某些需要互動式終端機（TTY）的程式無法正常運作。

**原因：**
WinRM 不提供真正的 TTY/PTY，它是基於 SOAP 協定的遠端管理，不是互動式 shell。

**影響：**
- 無法執行需要即時輸入的互動式程式
- 某些 CLI 工具的進度條、顏色輸出可能異常
- 像 Claude Code 這類工具的互動模式可能無法正常使用

**建議：**
如果需要完整的互動式終端，請改用 **SSH**（見 SSH 設定筆記）。

---

### 問題 3：中文輸出亂碼

**現象：**
透過 WinRM 執行指令時，中文顯示為亂碼。
例如：`.\claude.exe --print "請用一句話解釋 AVX 是什麼"` 的回應變成亂碼。

**原因：**
- WinRM 用 SOAP/XML 傳輸，中間經過序列化/反序列化
- 原生 .exe 的 stdout 編碼跟 PowerShell 的處理可能不一致
- Client 端的 console 編碼也會影響最終顯示

**解決方案：**

**方案 A - 設定 Console 編碼為 UTF-8（先試這個）：**
```powershell
Invoke-Command -ComputerName <電腦名稱> -Credential (Get-Credential) -ScriptBlock {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8

    # 你的指令
    .\claude.exe --print "請用一句話解釋 AVX 是什麼"
}
```

**方案 B - 改 Code Page 為 65001 (UTF-8)：**
```powershell
Invoke-Command -ComputerName <電腦名稱> -Credential (Get-Credential) -ScriptBlock {
    chcp 65001 | Out-Null
    .\claude.exe --print "請用一句話解釋 AVX 是什麼"
}
```

**方案 C - 設定環境變數：**
```powershell
Invoke-Command -ComputerName <電腦名稱> -Credential (Get-Credential) -ScriptBlock {
    $env:LANG = "en_US.UTF-8"
    .\claude.exe --print "請用一句話解釋 AVX 是什麼"
}
```

**方案 D - 使用 SSH 替代（最推薦）：**
SSH 是 byte-transparent 的，編碼問題少很多。如果上述方案都無效，建議改用 SSH。

> **備註：** WinRM 的編碼問題不一定能完美解決，這是 WinRM 架構的限制。

---

## WinRM vs SSH 比較

| 項目 | WinRM | SSH |
|------|-------|-----|
| TTY 支援 | 無 | 有 |
| 中文編碼 | 較麻煩 | 良好 |
| 設定複雜度 | 簡單 | 稍複雜 |
| 適用場景 | 自動化腳本、批次指令 | 互動式操作、開發 |

---

## 安全建議

- 僅在信任的私人網路使用
- 考慮設定 TrustedHosts 限制可連線的來源
- 如需跨網路使用，建議搭配 VPN
