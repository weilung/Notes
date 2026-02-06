# Windows RDP (遠端桌面) 設定筆記

## 概述

RDP (Remote Desktop Protocol) 讓你可以遠端登入 Windows 桌面環境，獲得完整的 GUI 操作體驗。

**注意：** Windows 10/11 Home 版無法作為 RDP Server，只有 Pro / Education / Enterprise 可以。

---

## 快速設定步驟

### 1. 確認 Windows 版本

```powershell
# Win + R → winver
# 或
(Get-WmiObject Win32_OperatingSystem).Caption
```

必須是 **Pro / Education / Enterprise** 才能當 RDP Server。

### 2. 啟用遠端桌面

**方法 A - GUI（最直覺）：**
1. 設定 → 系統 → 遠端桌面
2. 打開「啟用遠端桌面」
3. 建議同時開啟：
   - ✅「讓電腦保持喚醒以供連線」
   - ✅「僅允許使用網路層級驗證的連線（NLA）」

**方法 B - 命令列：**
```powershell
# 啟用 RDP
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0

# 啟用防火牆規則
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

### 3. 設定可登入的帳號

RDP **不能用沒有密碼的帳號**。

1. 遠端桌面設定頁 → 點「選取可遠端存取的使用者」
2. 加入你要登入的帳號

### 4. 確認防火牆

```powershell
# 檢查防火牆規則
Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Format-Table Name, Enabled, Direction
```

確認 `Remote Desktop - User Mode (TCP-In)` 是 **Enabled = True**。

---

## 從另一台電腦連線

### Windows Client

```powershell
# Win + R
mstsc
```

輸入電腦名稱或 IP（例如 `192.168.1.112`），然後輸入帳號密碼。

### Mac / 手機

使用 **Microsoft Remote Desktop** App（iOS / Android / macOS 都有）。

---

## 診斷問題：連線失敗排查

如果遇到「遠端桌面無法連線到遠端電腦」錯誤，依序執行以下診斷：

### 1. 確認 RDP 服務狀態

```powershell
Get-Service TermService, UmRdpService | Format-Table Name, Status, StartType
```

- `TermService`（Remote Desktop Services）應該是 **Running**
- `UmRdpService`（Remote Desktop Services UserMode Port Redirector）應該是 **Running**

### 2. 確認 RDP-TCP Listener 設定

```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" | Select-Object fEnableWinStation, PortNumber, UserAuthentication
```

- `fEnableWinStation` = **1**（啟用）
- `PortNumber` = **3389**
- `UserAuthentication` = **1**（NLA 啟用，建議保持）

### 3. 確認 3389 Port 是否在監聽

```powershell
netstat -ano | findstr :3389
```

應該看到類似：
```
TCP    0.0.0.0:3389    0.0.0.0:0    LISTENING    1234
```

**如果完全沒東西** → RDP Listener 沒有成功啟動，這是問題所在。

### 4. 從 Client 端測試連線

在要連線的電腦上執行：

```powershell
Test-NetConnection -ComputerName 192.168.1.112 -Port 3389
```

- `TcpTestSucceeded = True` → 網路通、Port 有開
- `TcpTestSucceeded = False` → 防火牆阻擋或服務沒跑

### 5. 重啟 RDP 服務

```powershell
Restart-Service TermService -Force
# 等幾秒後再查
netstat -ano | findstr :3389
```

### 6. 檢查 Event Log

```powershell
Get-WinEvent -LogName "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" -MaxEvents 10 | Format-Table TimeCreated, Id, Message -Wrap
```

看有沒有錯誤訊息提示問題原因。

---

## 遇到的問題與解決方案

### 問題 1：netstat 看不到 3389（Listener 沒起來）

**現象：**
- 設定都正確
- 服務顯示 Running
- 但 `netstat -ano | findstr :3389` 沒有任何輸出

**可能原因：**
1. 服務狀態異常（需重啟）
2. 第三方軟體衝突
3. RDP-TCP Listener 被停用
4. 憑證問題

**解決步驟：**
```powershell
# 1. 強制重啟服務
Restart-Service TermService -Force

# 2. 如果還是沒有，嘗試重新註冊 RDP listener
# （需要系統管理員權限）
$rdp = Get-WmiObject -Class Win32_TSGeneralSetting -Namespace root\cimv2\terminalservices
$rdp.SetUserAuthenticationRequired(1)

# 3. 檢查 Event Log 找具體錯誤
Get-WinEvent -LogName "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational" -MaxEvents 20
```

> **備註：** 如果以上都無效，可能需要檢查顯示驅動或考慮重裝 RDP 元件。

---

### 問題 2：NLA 認證錯誤

**錯誤訊息：**
> 發生驗證錯誤。無法連絡本機安全性授權。

**原因：**
CredSSP 認證問題，通常發生在 Windows Update 後。

**解決方案（暫時）：**
```powershell
# 關閉 NLA（不建議長期使用）
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 0 /f

# 開回 NLA
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v UserAuthentication /t REG_DWORD /d 1 /f
```

> **注意：** 關閉 NLA 會降低安全性。如果你的問題是「根本連不上」而不是「認證錯誤」，關閉 NLA 不會有幫助。

---

## Win10 RDP 的限制

| 項目 | Win10 Pro | Windows Server |
|------|-----------|----------------|
| 同時連線數 | 1 人 | 多人（需授權） |
| 本機使用者會被踢掉 | 是 | 否 |
| 多人各自獨立桌面 | 不行 | 可以 |

Win10 RDP 是「遠端登入」，不是「遠端協助」。連上後本機使用者會被登出。

---

## 安全建議

- 保持 NLA 啟用
- 使用強密碼
- 不要直接暴露 3389 到公網（容易被掃描爆破）
- 從外網連線建議：
  - ⭐ 先連 VPN，再用 RDP
  - 或改 RDP port + 防火牆白名單（次佳）
