# Hyper-V 虛擬機安裝筆記

## 環境資訊
- 主機系統：Windows
- 虛擬機用途：Windows 10 RDP 遠端桌面服務
- 建立日期：2026-02-04

---

## 一、BIOS 設定

在安裝 Hyper-V 之前，必須先在 BIOS 中啟用虛擬化技術：

1. 重新開機，進入 BIOS 設定（通常按 DEL、F2 或 F10）
2. 找到 **Intel Virtualization Technology (VT-x)** 或 **AMD-V**
3. 將其設定為 **Enabled（啟用）**
4. 儲存並退出 BIOS

> 注意：許多電腦出廠時預設關閉此功能

---

## 二、啟用 Hyper-V

### 方法一：透過 Windows 功能（GUI）
1. 開啟「控制台」→「程式和功能」→「開啟或關閉 Windows 功能」
2. 勾選「Hyper-V」（包含所有子項目）
3. 點擊「確定」並重新開機

### 方法二：透過 PowerShell（系統管理員）
```powershell
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
```

### 驗證 Hyper-V 狀態
```powershell
# 檢查 Hyper-V 功能狀態
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

# 檢查 Hypervisor 是否運行
(Get-WmiObject Win32_ComputerSystem).HypervisorPresent
```

---

## 三、防火牆設定

Hyper-V 安裝後會自動建立相關防火牆規則，以下規則應為啟用狀態：

| 規則名稱 | 狀態 |
|---------|------|
| Hyper-V - WMI (DCOM-In) | Enabled |
| Hyper-V - WMI (TCP-In) | Enabled |
| Hyper-V - WMI (TCP-Out) | Enabled |
| Hyper-V - WMI (Async-In) | Enabled |
| Hyper-V (RPC-EPMAP) | Enabled |
| Hyper-V (RPC) | Enabled |
| Hyper-V (MIG-TCP-In) | Enabled |
| Hyper-V (REMOTE_DESKTOP_TCP_IN) | Enabled |

### 檢查防火牆規則
```powershell
Get-NetFirewallRule -DisplayGroup '*Hyper*' | Select-Object DisplayName, Enabled
```

---

## 四、建立虛擬機

### VM 配置資訊
| 項目 | 設定值 |
|-----|--------|
| 名稱 | Windows10-RDP |
| 世代 | 第 2 代 (Generation 2) |
| 記憶體 | 12 GB (12884901888 bytes) |
| 處理器 | 4 核心 |
| 虛擬硬碟位置 | D:\Hyper-V\Windows10-RDP.vhdx |
| VM 設定檔位置 | D:\Hyper-V\Windows10-RDP |
| 網路交換器 | External Switch（已從 Default Switch 切換） |
| 安裝 ISO | D:\software\SW_DVD5_Win_Pro_Ent_Edu_N_10_1803_64BIT_ChnTrad_-2_MLF_X21-79699.ISO |

### 方法一：透過 Hyper-V 管理員（GUI）
1. 開啟「Hyper-V 管理員」（執行 `virtmgmt.msc`）
2. 右鍵點擊主機名稱 →「新增」→「虛擬機器」
3. 依照精靈設定名稱、世代、記憶體、網路、硬碟
4. 選擇安裝 ISO 檔案
5. 完成建立

### 方法二：透過 PowerShell
```powershell
# 建立虛擬機
New-VM -Name "Windows10-RDP" `
       -Generation 2 `
       -MemoryStartupBytes 12GB `
       -Path "D:\Hyper-V" `
       -NewVHDPath "D:\Hyper-V\Windows10-RDP.vhdx" `
       -NewVHDSizeBytes 100GB `
       -SwitchName "Default Switch"

# 設定處理器數量
Set-VMProcessor -VMName "Windows10-RDP" -Count 4

# 掛載 ISO 檔案
Add-VMDvdDrive -VMName "Windows10-RDP" -Path "D:\software\SW_DVD5_Win_Pro_Ent_Edu_N_10_1803_64BIT_ChnTrad_-2_MLF_X21-79699.ISO"

# 設定 DVD 為第一開機裝置（重要！）
Set-VMFirmware -VMName "Windows10-RDP" -FirstBootDevice (Get-VMDvdDrive -VMName "Windows10-RDP")
```

---

## 五、開機順序設定

第 2 代 VM 使用 UEFI，預設開機順序可能不正確，需要將 DVD 設為第一開機裝置：

### 問題現象
如果看到 "Boot loader failed" 或 "No operating system was loaded" 錯誤，表示開機順序不正確。

### 解決方法
```powershell
# 關閉 VM
Stop-VM -Name "Windows10-RDP" -Force

# 設定 DVD 為第一開機裝置
Set-VMFirmware -VMName "Windows10-RDP" -FirstBootDevice (Get-VMDvdDrive -VMName "Windows10-RDP")

# 確認開機順序
Get-VMFirmware -VMName "Windows10-RDP" | Select-Object -ExpandProperty BootOrder
```

正確的開機順序應該是：
1. DVD 光碟機（安裝時）
2. 網路介面卡
3. 硬碟

---

## 六、安裝 Windows 10

### 啟動 VM 並連線
```powershell
# 啟動虛擬機
Start-VM -Name "Windows10-RDP"

# 開啟 VM 連線視窗
vmconnect localhost "Windows10-RDP"
```

### 安裝步驟
1. 看到 "Press any key to boot from CD or DVD..." 時，**快速按任意鍵**
2. 選擇語言、時間格式、鍵盤 → 下一步
3. 點擊「立即安裝」
4. 輸入產品金鑰（或選擇「我沒有產品金鑰」）
5. 選擇 **Windows 10 專業版**（較省資源）
6. 接受授權條款
7. 選擇「自訂：只安裝 Windows（進階）」
8. 選擇磁碟 → 下一步
9. 等待安裝完成（會自動重新開機數次）
10. 完成初始設定（建立使用者帳戶等）

### Windows 版本選擇建議
| 版本 | 資源消耗 | 建議 |
|-----|---------|------|
| 專業版 | 最少 | 推薦用於 RDP |
| 專業教育版 | 少 | 與專業版相近 |
| 企業版 | 較多 | 有額外服務 |
| 教育版 | 較多 | 功能同企業版 |

---

## 七、VM 管理常用指令

```powershell
# 列出所有 VM
Get-VM

# 啟動 VM
Start-VM -Name "Windows10-RDP"

# 關閉 VM（正常關機）
Stop-VM -Name "Windows10-RDP"

# 強制關閉 VM
Stop-VM -Name "Windows10-RDP" -Force

# 重新啟動 VM
Restart-VM -Name "Windows10-RDP"

# 查看 VM 狀態
Get-VM -Name "Windows10-RDP" | Select-Object Name, State, CPUUsage, MemoryAssigned

# 連線到 VM
vmconnect localhost "Windows10-RDP"

# 透過 PowerShell Direct 在 VM 內執行指令（不需網路）
Invoke-Command -VMName "Windows10-RDP" -Credential (Get-Credential) -ScriptBlock { 指令 }
```

---

## 八、SMB 共享設定

讓 VM 可以存取主機的磁碟：

### 在主機建立共享
```powershell
# 建立 D: 磁碟的 SMB 共享（需系統管理員權限）
New-SmbShare -Name "D_Share" -Path "D:\" -FullAccess "Everyone"
```

### 在 VM 內存取
```
\\172.28.0.1\D_Share
```
> 需輸入主機的 Windows 帳戶密碼

### 主機虛擬網路 IP
- Default Switch: 172.28.0.1

---

## 九、RDP 遠端桌面設定

### 透過 PowerShell Direct 設定（從主機執行）
```powershell
$pw = ConvertTo-SecureString 'PASSWORD' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Pinecone', $pw)

Invoke-Command -VMName 'Windows10-RDP' -Credential $cred -ScriptBlock {
    # 啟用 RDP
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0

    # 啟用網路層級驗證 (NLA)
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value 1

    # 建立 RDP 防火牆規則
    New-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389 -Action Allow

    # RDP 服務設定為自動啟動
    Set-Service -Name 'TermService' -StartupType Automatic
}
```

### RDP 連線資訊
| 項目 | 值 |
|-----|-----|
| VM IP | 192.168.1.105（固定 IP） |
| Port | 3389 |
| 帳號 | Pinecone |

---

## 十、系統優化

### 停用的服務
| 服務名稱 | 說明 |
|---------|------|
| SysMain | Superfetch 預先載入 |
| WSearch | Windows 搜尋索引 |
| DiagTrack | 遙測資料收集 |
| dmwappushservice | WAP 推播 |
| MapsBroker | 離線地圖管理 |
| lfsvc | 定位服務 |
| RetailDemo | 展示模式 |
| WMPNetworkSvc | 媒體播放器分享 |
| XblAuthManager | Xbox Live 驗證 |
| XblGameSave | Xbox Live 存檔 |
| XboxNetApiSvc | Xbox Live 網路 |
| wisvc | Windows Insider |
| icssvc | 行動熱點 |
| WbioSrvc | 生物辨識 |
| TabletInputService | 觸控鍵盤 |

### 停用服務指令
```powershell
$services = @('SysMain','WSearch','DiagTrack','dmwappushservice','MapsBroker',
    'lfsvc','RetailDemo','WMPNetworkSvc','XblAuthManager','XblGameSave',
    'XboxNetApiSvc','wisvc','icssvc','WbioSrvc','TabletInputService')

foreach ($svc in $services) {
    Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
}
```

### 其他優化項目
| 項目 | 設定 |
|-----|------|
| 視覺特效 | 最佳效能 |
| 透明效果 | 關閉 |
| 選單動畫延遲 | 關閉 (0ms) |
| 自動維護 | 關閉 |
| 遊戲模式 | 關閉 |
| 電源計畫 | 高效能 |

---

## 十一、External 虛擬交換器

Default Switch (Internal) 只有主機能存取 VM，家裡其他電腦無法 RDP 連線。
需改用 External Switch 讓 VM 直接連到家用路由器。

### 建立 External Switch
```powershell
# 使用實體網卡建立 External Switch（會短暫中斷網路）
New-VMSwitch -Name "External Switch" -NetAdapterName (Get-NetAdapter -Physical | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1 -ExpandProperty Name) -AllowManagementOS $true
```

### 連接 VM 到 External Switch
```powershell
Get-VM -Name 'Windows10-RDP' | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName 'External Switch'
```

### 主機實體網卡
- Realtek PCIe GBE Family Controller

---

## 十二、固定 IP 設定

使用 External Switch 後，VM 從家用路由器取得 IP（與其他電腦同網段）。
設定固定 IP 確保 RDP 連線地址不變。

### 透過 PowerShell Direct 設定
```powershell
$pw = ConvertTo-SecureString 'PASSWORD' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential('Pinecone', $pw)

Invoke-Command -VMName 'Windows10-RDP' -Credential $cred -ScriptBlock {
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

    # 移除現有 IP 設定
    Remove-NetIPAddress -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue
    Remove-NetRoute -InterfaceAlias $adapter.Name -Confirm:$false -ErrorAction SilentlyContinue

    # 設定固定 IP
    New-NetIPAddress -InterfaceAlias $adapter.Name -IPAddress '192.168.1.105' -PrefixLength 24 -DefaultGateway '192.168.1.1'

    # 設定 DNS
    Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses @('192.168.1.1', '8.8.8.8')
}
```

### VM 網路配置
| 項目 | 值 |
|-----|-----|
| IP | 192.168.1.105 |
| 子網路遮罩 | 255.255.255.0 (/24) |
| 預設閘道 | 192.168.1.1 |
| DNS | 192.168.1.1, 8.8.8.8 |
| MAC | 00-15-5D-01-70-00 |

---

## 十三、自動啟動 VM

### 設定指令
```powershell
# 主機開機後 30 秒自動啟動 VM
Set-VM -Name 'Windows10-RDP' -AutomaticStartAction Start -AutomaticStartDelay 30

# 主機關機時儲存 VM 狀態（需 VM 關閉時設定）
Set-VM -Name 'Windows10-RDP' -AutomaticStopAction Save
```

### 目前設定
| 項目 | 值 |
|-----|-----|
| 自動啟動 | Start（主機開機後 30 秒） |
| 自動停止 | Save（儲存狀態，類似休眠） |

---

## 十四、從母版複製 VM

母版 (Windows10-RDP) 不直接使用，複製出新 VM 來日常使用。

### Clone 腳本位置
`D:\Hyper-V\Clone-VM.ps1`

### 使用方式
```powershell
# 基本用法（DHCP）
.\Clone-VM.ps1 -Name "Win10-A"

# 指定固定 IP
.\Clone-VM.ps1 -Name "Win10-A" -IP "192.168.1.106"

# 自訂資源
.\Clone-VM.ps1 -Name "Win10-B" -IP "192.168.1.107" -RAM 8 -CPU 2
```

### 參數
| 參數 | 必填 | 預設值 | 說明 |
|-----|------|--------|------|
| `-Name` | 是 | - | 新 VM 名稱 |
| `-IP` | 否 | DHCP | 固定 IP |
| `-RAM` | 否 | 12 (GB) | 記憶體 |
| `-CPU` | 否 | 4 | CPU 核心數 |

### 腳本自動執行的步驟
1. 關閉母版 VM
2. 複製 VHDX
3. 建立 VM（第 2 代、External Switch）
4. 設定 CPU / RAM / 開機順序 / 自動啟動
5. 啟動 VM
6. 啟用 RDP + 防火牆規則
7. 設定固定 IP（如有指定）

### 目前的 VM 列表
| VM | IP | 用途 |
|----|-----|------|
| Windows10-RDP | 192.168.1.105 | 母版（不使用） |
| Win10-A | 192.168.1.106 | 日常使用 |

---

## 十五、完成事項

- [x] BIOS 啟用 Intel VT-x
- [x] 啟用 Hyper-V
- [x] 建立虛擬機
- [x] 安裝 Windows 10 專業版
- [x] 啟用 RDP 遠端桌面
- [x] 設定防火牆允許 RDP
- [x] 系統優化（關閉不必要的服務和特效）
- [x] SMB 共享設定
- [x] 建立 External 虛擬交換器
- [x] 設定固定 IP
- [x] 設定自動啟動 VM
- [x] 建立 Clone 腳本（含自動啟用 RDP）
- [x] 從母版複製 Win10-A

---

## 注意事項

### CMOS 電池問題
如果主機完全斷電後 BIOS 設定被重置（Intel VT-x 被關閉），代表 CMOS 電池沒電，需更換 CR2032 鈕扣電池。

### 通用系統優化腳本
已建立獨立腳本：`D:\software\Windows10_Optimize.ps1`
可在任何 Windows 10 電腦上以系統管理員身份執行：
```powershell
powershell -ExecutionPolicy Bypass -File "D:\software\Windows10_Optimize.ps1"
```

### 複製 VM 後注意事項
- 複製的 VM 與母版有相同的 SID 和電腦名稱，家用環境下不影響使用
- 如需加入網域，應先執行 Sysprep 一般化再複製
- 每台 VM 需設定不同的固定 IP，避免衝突

---

## 參考資源
- [Microsoft Hyper-V 官方文件](https://docs.microsoft.com/zh-tw/virtualization/hyper-v-on-windows/)
- [PowerShell Hyper-V 模組](https://docs.microsoft.com/zh-tw/powershell/module/hyper-v/)
