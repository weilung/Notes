# Windows SSH Server 設定筆記

## 概述

Windows 10/11 內建 OpenSSH Server，啟用後可透過 SSH 連線，提供完整的互動式終端體驗，適合遠端開發、執行 CLI 工具（如 Claude Code）。

---

## 快速設定步驟

### 1. 安裝 OpenSSH Server

以系統管理員身分開啟 PowerShell：

```powershell
# 檢查是否已安裝
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH*'

# 安裝 OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

### 2. 啟動 SSH 服務

```powershell
# 啟動服務
Start-Service sshd

# 設定開機自動啟動
Set-Service -Name sshd -StartupType Automatic
```

### 3. 確認防火牆規則

```powershell
# 檢查是否有 SSH 防火牆規則
Get-NetFirewallRule -Name *ssh*

# 如果沒有，手動新增（通常安裝時會自動建立）
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```

### 4. 驗證服務狀態

```powershell
Get-Service sshd
```

Status 顯示 `Running` 即成功。

---

## 從另一台電腦連線

### 基本連線

```bash
ssh username@hostname
# 或
ssh username@192.168.x.x
```

### 使用 PowerShell 作為預設 Shell（推薦）

預設 SSH 登入後是 cmd.exe，建議改成 PowerShell：

```powershell
# 在 Server 端執行（系統管理員）
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
```

如果要用 PowerShell 7：

```powershell
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
```

---

## SSH 登入權限說明

SSH 登入後的權限取決於該 Windows 帳號的身分，且**不經過 UAC**：

| 帳號類型 | SSH 登入後的權限 |
|----------|-----------------|
| 一般使用者 | 一般權限 |
| Administrators 群組成員 | **直接獲得管理員權限** |

這與本機操作不同：在本機即使是管理員帳號，執行需要提升權限的操作時會跳出 UAC 提示。但 SSH 登入不會觸發 UAC，管理員帳號登入後直接就是完整的管理員權限。

> **安全提醒**：正因為 SSH 繞過 UAC，管理員帳號的 SSH 存取應特別注意保護（使用 Key 認證、限制來源 IP 等）。

---

## SSH Key 認證（免密碼登入）

### 1. 在 Client 端產生金鑰

```bash
ssh-keygen -t ed25519
```

若已有現成的 key（例如用於 GitHub），可直接沿用，不需重新產生。

### 2. 複製公鑰到 Server

> ⚠️ **重要：管理員帳號與一般使用者的公鑰存放位置不同！**
>
> Windows OpenSSH 的 `sshd_config` 預設包含以下規則：
> ```
> Match Group administrators
>     AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
> ```
> 這表示 Administrators 群組的成員，公鑰**必須**放在 `C:\ProgramData\ssh\administrators_authorized_keys`，放在個人的 `~\.ssh\authorized_keys` 不會生效。

| 帳號類型 | 公鑰存放位置 |
|----------|-------------|
| 一般使用者 | `C:\Users\<username>\.ssh\authorized_keys` |
| Administrators 群組成員 | `C:\ProgramData\ssh\administrators_authorized_keys` |

**方法 A - 從 Windows Client 用 PowerShell 複製（推薦）：**

```powershell
# 一行指令，執行時需輸入一次密碼
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh Pinecone@192.168.1.x "Add-Content -Path 'C:\ProgramData\ssh\administrators_authorized_keys' -Value (Read-Host)"
```

**方法 B - 手動複製：**

把 Client 端的 `~/.ssh/id_ed25519.pub` 內容貼到 Server 端對應位置。

**方法 C - 使用 ssh-copy-id（Linux/Mac Client）：**

```bash
ssh-copy-id username@server
```

### 3. 設定管理員帳號的 authorized_keys 權限

Windows OpenSSH 對權限很嚴格，若 `administrators_authorized_keys` 權限設定不正確，key 認證會被忽略。

```powershell
# 在 Server 端執行（簡潔版）
icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "SYSTEM:F" /grant "Administrators:F"
```

或使用 PowerShell 詳細版：

```powershell
$acl = Get-Acl C:\ProgramData\ssh\administrators_authorized_keys
$acl.SetAccessRuleProtection($true, $false)
$adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrators","FullControl","Allow")
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM","FullControl","Allow")
$acl.SetAccessRule($adminRule)
$acl.SetAccessRule($systemRule)
Set-Acl C:\ProgramData\ssh\administrators_authorized_keys $acl
```

兩者效果相同，`icacls` 較簡潔，PowerShell 版較適合放在自動化腳本中。

---

## 常用 SSH 設定檔調整

設定檔位置：`C:\ProgramData\ssh\sshd_config`

```conf
# 允許密碼認證（預設開啟）
PasswordAuthentication yes

# 允許公鑰認證（預設開啟）
PubkeyAuthentication yes

# 修改後重啟服務
# Restart-Service sshd
```

---

## 為什麼選擇 SSH 而非 WinRM

| 優勢 | 說明 |
|------|------|
| 完整 TTY 支援 | 可執行互動式程式，如 vim、htop、Claude Code 互動模式 |
| UTF-8 編碼良好 | 中文輸出正常，不會亂碼 |
| 跨平台通用 | Linux、Mac、Windows 都用相同方式連線 |
| 金鑰認證 | 比密碼更安全，且免輸入 |
| 工具生態豐富 | VS Code Remote SSH、SCP、SFTP 等 |

---

## 搭配 VS Code Remote SSH 使用

### 安裝與連線

1. **安裝擴充套件**：在 VS Code 搜尋並安裝 `Remote - SSH`
2. **連線到遠端主機**：
   - `Ctrl+Shift+P` → 輸入 `Remote-SSH: Connect to Host`
   - 輸入 `username@hostname` 或 `username@192.168.x.x`
3. **開啟遠端資料夾**：
   - 連線成功後，VS Code 會重新開啟一個視窗
   - `File` → `Open Folder` → 選擇遠端路徑（例如 `D:\Projects\MyApp`）

### 連線後的效果

- VS Code 左下角顯示 `SSH: hostname`，代表正在編輯遠端檔案
- 檔案總管顯示的是**遠端主機的磁碟**（可以開 C:、D: 等任意路徑）
- 終端機開啟的是**遠端主機的 shell**
- 擴充套件會自動安裝到遠端（例如裝 Python 擴充套件，它會裝在遠端主機）

### 儲存常用連線（可選）

編輯 SSH config 檔案，之後連線更方便：

**Windows Client**：`C:\Users\<你的使用者>\.ssh\config`

```
Host my-server
    HostName 192.168.1.100
    User username
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
```

之後在 VS Code 連線時，直接選 `my-server` 即可。

> **提示**：`IdentityFile` 指定使用哪把 key，`IdentitiesOnly yes` 確保只用該 key 認證，不會嘗試其他 key。若有多個 SSH key（例如同時用於 GitHub 和內網機器），建議明確指定避免混淆。

### 搭配 Claude Code 使用注意事項

若本機 CPU 不支援 AVX 指令集，無法直接安裝 Claude Code，可透過 Remote-SSH 連到支援 AVX 的遠端機器，由遠端執行 Claude Code，本機只負責顯示介面。VS Code 的 Claude Code 擴充套件同樣需要遠端機器支援 AVX，因此擴充套件也應安裝在遠端端。

---

## 檔案傳輸（SCP / SFTP）

透過 SSH 通道即可傳輸檔案，不需要額外設定。

### scp（單次複製）

```bash
# 複製遠端檔案到本地
scp username@server:D:/path/to/file.txt ./local/

# 複製遠端資料夾到本地（需加 -r）
scp -r username@server:D:/path/to/folder ./local/

# 複製本地檔案到遠端
scp ./local/file.txt username@server:D:/path/to/
```

### sftp（互動式）

```bash
sftp username@server
# 進入後可用 ls, cd 瀏覽遠端
get file.txt           # 下載單檔
get -r folder          # 下載資料夾
put file.txt           # 上傳單檔
```

---

## 搭配 Claude Code 使用

SSH 連線後，可以正常執行 Claude Code：

```bash
ssh user@server
cd /path/to/project
claude
```

因為 SSH 提供完整 TTY，Claude Code 的互動介面可正常運作。

---

## 安全建議

- 使用 SSH Key 認證，停用密碼認證
- 修改預設 Port 22（如改成 2222）
- 使用防火牆限制來源 IP
- 定期更新 Windows 以獲得 OpenSSH 安全修補
- 如需從外網連線，建議搭配 VPN 或使用跳板機
