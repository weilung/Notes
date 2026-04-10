# OpenSpec 使用教學筆記

> 使用 Claude Code CLI 搭配 OpenSpec 進行規格驅動開發的實際操作記錄。

## 什麼是 OpenSpec

OpenSpec 是一個 AI 原生的規格驅動開發系統（AI-native spec-driven development），核心理念是在寫程式之前，先讓人和 AI 對「要做什麼」達成共識。

- 官方定位：fluid not rigid、iterative not waterfall
- 適用於全新專案（greenfield）和既有專案（brownfield）
- 透過 Claude Code 的 slash command 操作

## 安裝

```bash
npm install -g @fission-ai/openspec@latest
```

安裝後預設有以下指令可用：

| 指令 | 用途 |
|------|------|
| `/opsx:propose` | 規劃：產出提案、規格、設計、任務清單 |
| `/opsx:apply` | 實作：按任務清單逐步寫程式 |
| `/opsx:archive` | 歸檔：完成後存檔並同步規格 |
| `/opsx:explore` | 探索：在開始前釐清需求和想法 |

> 可透過 `openspec config profile` 安裝更多指令（如 `/opsx:new`、`/opsx:continue`、`/opsx:verify` 等）。

## 三個核心階段

```
Propose（規劃）→ Apply（實作）→ Archive（歸檔）
```

### Propose 階段

執行 `/opsx:propose`，描述你想做什麼，OpenSpec 會依序產出：

1. **proposal.md** — 為什麼要做（問題、範圍、影響）
2. **specs/** — 每個功能的詳細需求與場景（WHEN/THEN 格式）
3. **design.md** — 技術決策與架構（怎麼做、為什麼這樣做）
4. **tasks.md** — 實作任務清單（checkbox 格式）

### Apply 階段

執行 `/opsx:apply`，它會：

- 讀取所有規劃文件作為上下文
- 按 tasks.md 的順序逐一實作
- 完成一個任務就勾選 `- [ ]` → `- [x]`
- **不會在任務群組之間暫停**，會一口氣做完所有任務

### Archive 階段

執行 `/opsx:archive`，將完成的 change 移至 `openspec/changes/archive/` 並可同步規格到主庫。

## 目錄結構

`openspec/` 只有三個東西：`config.yaml`、`specs/`、`changes/`，不會有其他檔案或目錄。

```
your-project/
├── .claude/                         # Claude Code 指令定義（由 openspec init 產生）
│   ├── commands/opsx/               # slash command 定義
│   └── skills/                      # skill 定義
├── openspec/
│   ├── config.yaml                  # 專案設定（schema、context、rules）
│   ├── specs/                       # 主規格庫（系統的完整功能規格）
│   │   ├── user-auth/spec.md
│   │   ├── bookmark-crud/spec.md
│   │   ├── tagging/spec.md
│   │   ├── bookmark-search/spec.md
│   │   ├── dashboard/spec.md
│   │   ├── collections/spec.md
│   │   └── public-sharing/spec.md
│   └── changes/                     # 變更管理
│       ├── <change-name>/           # 進行中的 change
│       │   ├── .openspec.yaml       # Change 的 metadata
│       │   ├── proposal.md          # 提案文件
│       │   ├── design.md            # 設計文件
│       │   ├── tasks.md             # 任務清單
│       │   └── specs/               # Delta specs（差異規格）
│       │       └── <capability>/spec.md
│       └── archive/                 # 已歸檔的 changes
│           └── YYYY-MM-DD-<name>/
```

### `openspec/specs/`（主規格庫）

這是系統功能的**唯一真相來源**（single source of truth），記錄系統目前**完整**的功能規格。

**每個子目錄代表一個 capability（功能領域）：**
- 每個 capability 只有一個 `spec.md` 檔案
- 內容包含該功能的所有 Requirements 和 Scenarios
- 使用 `SHALL`/`MUST` 等規格語言的標準用詞
- 每個 Requirement 至少有一個 `WHEN/THEN` 場景（等於驗收標準）

**主規格庫的用途：**
1. **Propose 時的參考** — OpenSpec 讀取主規格庫，才知道哪些功能已存在，才能正確產出 `MODIFIED`（修改）而非 `ADDED`（新增）
2. **系統的活文件** — 整個系統「目前該做什麼」的完整定義
3. **AI 實作時的上下文** — apply 時 AI 讀這些 specs 來理解系統全貌

**累積機制：**

每次 archive + sync 後，主規格庫的 spec 會被更新成合併後的最新版本。以 `bookmark-crud/spec.md` 為例：

| 輪次 | Change | 變化 |
|------|--------|------|
| 第一輪 | bookmark-manager | 初始版本：Create、List、Get、Update、Delete |
| 第二輪 | add-collections | MODIFIED：加入 collectionId 相關欄位和場景 |
| 第四輪 | add-favorites | MODIFIED：加入 IsFavorite、Toggle favorite |

### `openspec/changes/`（變更管理）

**進行中的 change** 放在 `changes/<name>/`，每個 change 包含：
- `.openspec.yaml` — metadata（schema、狀態）
- `proposal.md` — 為什麼要做
- `design.md` — 怎麼做
- `tasks.md` — 實作任務清單
- `specs/` — **Delta specs**（差異規格），只記錄要新增或修改的部分

**Delta specs vs 主規格庫 specs 的區別：**

| | `openspec/specs/<capability>/spec.md` | `changes/<name>/specs/<capability>/spec.md` |
|---|---|---|
| **角色** | 主規格（canonical） | 差異規格（delta） |
| **內容** | 完整的功能規格 | 只有 ADDED / MODIFIED / REMOVED 的部分 |
| **生命週期** | 持久存在，持續累積 | archive + sync 後合併回主規格，原始 change 移至 archive |

**已歸檔的 change** 放在 `changes/archive/YYYY-MM-DD-<name>/`，保留完整的歷史記錄。

## 實際操作記錄

### 練習專案：個人書籤管理系統（Bookmark Manager）

**技術棧：**
- 前端：React 18+（Vite + TypeScript + Tailwind CSS）
- 後端：ASP.NET Core 8+ Web API
- 資料庫：SQL Server LocalDB + Entity Framework Core
- 認證：JWT Bearer Token

### 步驟 1：初始化 OpenSpec

```bash
openspec init
```

在專案目錄產生 `openspec/` 資料夾和 `config.yaml`。

> **時機**：可以在建專案前或建專案後執行，都可以。

### 步驟 2：Propose

在 Claude Code CLI 執行 `/opsx:propose`，選擇：
1. New feature
2. Type something（自由輸入，不被限制在單一類別）

貼上需求描述：

```
建立一個個人書籤管理系統（Bookmark Manager）。

功能需求：
- 使用者註冊與登入（JWT 認證）
- 書籤 CRUD（新增、瀏覽、編輯、刪除）
- 書籤可加標籤（Tags），多對多關聯
- 依標題、網址、標籤搜尋書籤
- 簡單儀表板顯示書籤數量、常用標籤等統計

技術棧：
- 前端：React 18+（Vite + TypeScript + Tailwind CSS）
- 後端：ASP.NET Core 8+ Web API
- 資料庫：SQL Server LocalDB + Entity Framework Core
- 認證：JWT Bearer Token
- 前後端分離，透過 REST API 溝通
```

**產出結果：**

| 文件 | 說明 |
|------|------|
| proposal.md | 專案摘要、功能列表、影響範圍 |
| specs/user-auth/spec.md | 使用者認證的需求與場景 |
| specs/bookmark-crud/spec.md | 書籤 CRUD 的需求與場景 |
| specs/tagging/spec.md | 標籤系統的需求與場景 |
| specs/bookmark-search/spec.md | 搜尋功能的需求與場景 |
| specs/dashboard/spec.md | 儀表板的需求與場景 |
| design.md | 技術架構決策（monorepo、EF Core Code-First、JWT、REST） |
| tasks.md | 10 個群組、共 34 個實作任務 |

### 步驟 3：Commit Propose 結果

```bash
git init
git add openspec/ .claude/
git commit -m "chore(openspec): initialize project and propose bookmark-manager change"
```

### 步驟 4：Apply

在 Claude Code CLI 執行 `/opsx:apply`。

**執行行為注意事項：**
- 過程中會持續詢問權限（執行 bash、寫入檔案），需逐一同意
- **不會在任務群組之間暫停**，會一口氣完成所有任務
- 如果想按群組分批 commit，需要觀察到下一組任務開始時主動按 Esc 中斷
- 完成後會顯示 `Progress: 34/34 tasks complete`

**產出結果：**
- `backend/` — 完整的 ASP.NET Core Web API 專案
- `frontend/` — 完整的 React SPA 專案
- `tasks.md` 中所有任務都被勾選為完成

### 步驟 5：Commit Apply 結果

因為是一口氣完成，建議分成有意義的 commit：

```bash
# Commit 1 — 後端
git add backend/
git commit -m "feat(backend): implement ASP.NET Core 8 Web API"

# Commit 2 — 前端
git add frontend/ --force
git commit -m "feat(frontend): implement React 18 SPA with Vite + TypeScript + Tailwind"

# Commit 3 — OpenSpec 任務狀態更新
git add openspec/ .claude/
git commit -m "chore(openspec): mark all 34 tasks complete for bookmark-manager"
```

> 使用 `--force` 是因為 frontend 的 node_modules 可能被 .gitignore 忽略，但 frontend 目錄本身是新的未追蹤目錄。

## 步驟 6：驗證

啟動前後端確認功能正常：

```bash
# 終端機 1 — 後端
cd backend && dotnet run
# 看到 Now listening on: http://localhost:5082 代表成功

# 終端機 2 — 前端
cd frontend && npm run dev
# 看到 Local: http://localhost:5173/ 代表成功
```

打開瀏覽器到 `http://localhost:5173`，驗證：註冊 → 登入 → 新增書籤（含標籤）→ 搜尋 → 儀表板 → 編輯/刪除。

### 步驟 7：Archive

在 Claude Code CLI 執行 `/opsx:archive`。

**過程中的選項：**
- 會詢問是否 Sync delta specs to main specs → 選 **Sync now**
- 這會把此 change 建立的功能規格同步到 `openspec/specs/`，未來新的 change 可參考這些已存在的規格

**結果：**
- Change 移至 `openspec/changes/archive/2026-04-08-bookmark-manager/`
- 5 個功能規格同步到 `openspec/specs/`（user-auth、bookmark-crud、tagging、bookmark-search、dashboard）

```bash
git add openspec/
git commit -m "chore(openspec): archive bookmark-manager and sync specs to main"
```

**Spec Sync 的意義：**

這是 OpenSpec 規格累積的核心機制。歸檔時同步 specs，讓 `openspec/specs/` 成為系統功能的「主規格庫」。未來如果要修改或擴充功能，新的 change 會參考這些已存在的規格，使用 `MODIFIED` 或 `ADDED` 等標記來描述差異，而不是從零開始。

## 第二輪：在既有專案上新增功能（Add Collections）

這一輪體驗 OpenSpec 對既有專案做 change 的流程。

### 與第一輪的關鍵差異

**Delta Specs 出現了 `MODIFIED Requirements`：**

第一輪全部都是 `ADDED Requirements`（全新功能）。第二輪因為是擴充既有功能：
- `collections/spec.md` → `ADDED`（全新的收藏夾 CRUD）
- `bookmark-crud/spec.md` → `MODIFIED`（Create、List、Get、Update 加入 collectionId）
- `bookmark-search/spec.md` → `MODIFIED`（加入 collection 篩選）
- `dashboard/spec.md` → `MODIFIED`（加入收藏夾統計）

OpenSpec 會讀取 `openspec/specs/` 中已存在的規格，用 `MODIFIED` 標記差異，而不是重寫整份規格。

**規模對比：**
- 第一輪（全新專案）：34 個任務、10 個群組
- 第二輪（功能擴充）：20 個任務、7 個群組

### Propose 時的選項

執行 `/opsx:propose` 時：
- 選 **Enhancement**（改善/擴充現有功能），而非 New feature
- 選 **Type something** 自由輸入完整描述

OpenSpec 還會根據現有 specs 自動猜測可能的擴充方向（如 pagination、import/export、dark mode 等），但我們選自訂輸入。

### 提供的描述

```
新增書籤收藏夾（Collections）功能。

功能需求：
- 使用者可以建立、瀏覽、編輯、刪除收藏夾
- 每個收藏夾有名稱和可選的描述
- 書籤可以歸入一個收藏夾（一對多關係）
- 書籤也可以不屬於任何收藏夾
- 可以依收藏夾篩選書籤
- 儀表板顯示收藏夾數量統計

這是既有專案的功能擴充：
- 需要修改 bookmark-crud：書籤新增/編輯時可選擇收藏夾
- 需要修改 bookmark-search：支援依收藏夾篩選
- 需要修改 dashboard：加入收藏夾統計
- 新增 collections capability：收藏夾的 CRUD
```

### Archive 時的 Spec Sync

歸檔後同步結果：
- `collections` — **new**（新增到主規格庫）
- `bookmark-crud`、`bookmark-search`、`dashboard` — **modified**（主規格庫中的既有規格被更新）

這展示了 OpenSpec 規格累積的完整循環：propose 時參考主規格 → 用 MODIFIED 標記變更 → archive 時合併回主規格。

## 完整 Commit 歷程

| 順序 | Commit 訊息 | 內容 |
|------|------------|------|
| 1 | `chore(openspec): initialize project and propose bookmark-manager change` | openspec init + /opsx:propose 產出的規劃文件 |
| 2 | `feat(backend): implement ASP.NET Core 8 Web API` | 後端完整專案 |
| 3 | `feat(frontend): implement React 18 SPA with Vite + TypeScript + Tailwind` | 前端完整專案 |
| 4 | `chore(openspec): mark all 34 tasks complete for bookmark-manager` | tasks.md 勾選狀態更新 |
| 5 | `chore(openspec): archive bookmark-manager and sync specs to main` | 歸檔 + 規格同步 |
| 6 | `chore(openspec): propose add-collections change` | 收藏夾功能的規劃文件（1 new + 3 modified specs） |
| 7 | `feat: add collections feature for bookmark grouping` | 收藏夾功能的完整實作（前後端） |
| 8 | `chore(openspec): archive add-collections and sync specs to main` | 歸檔 + 規格同步（含 modified specs 合併） |

## 第三輪：Explore 探索模式

### 什麼是 `/opsx:explore`

Explore 是在 `/opsx:propose` 之前使用的「思考夥伴」模式。適合：
- 還不確定要做什麼功能
- 需求模糊，想先釐清範圍
- 想評估某個方向是否適合目前架構

**與 Propose 的差異：**
- Propose 會直接產出文件（proposal、specs、design、tasks）
- Explore 只是對話討論，不產出任何文件
- Explore 幫你收斂想法後，再用 Propose 正式建立 change

### 執行方式

在 Claude Code CLI 執行 `/opsx:explore`。

**初始回應：** 它會先掃描專案狀態，顯示目前已實作的功能和是否有進行中的 change，然後詢問你想探索什麼：

```
No active changes — clean slate. The Bookmark Manager has auth, CRUD, tags, 
search, dashboard, and collections all implemented.

What's on your mind? A new feature idea, a concern about the current architecture, 
something you want to rethink — or just want to browse what we've built and see 
what emerges?
```

然後提供一個開放性的問題讓它幫你分析，例如：

```
我在考慮是否要幫書籤系統加上分享功能，但不確定範圍該多大。
可能的方向有：公開分享連結、使用者之間分享收藏夾、或者匯出分享。
幫我想想哪種方式最適合目前的架構，以及要注意什麼。
```

### Explore 的回應特色

Explore 會讀取你的程式碼和現有架構，做出**有根據的分析**，而非空泛建議。以分享功能為例，它做了：

1. **掃描現有程式碼** — 了解目前的 Entity、Controller、查詢模式
2. **製作比較表** — 列出三種方向的複雜度、架構衝擊、安全考量、使用者價值
3. **逐一分析** — 每個方向需要改哪些檔案、加哪些 table、有什麼風險
4. **給出建議** — 根據目前架構推薦「公開分享連結」為甜蜜點
5. **追問** — 問你分享單位要 Collection 還是單一書籤，幫你進一步收斂

### 完整流程：Explore → Propose → Apply → Archive

這一輪完整走了：

1. `/opsx:explore` — 討論分享功能的三種方向，決定用公開分享連結
2. `/opsx:propose` — 產出 add-public-sharing 的規劃文件（14 個任務）
3. `/opsx:apply` — 實作完成
4. `/opsx:archive` — 歸檔，同步 public-sharing（new）和 collections（modified）

### Commit 順序的教訓

這一輪因為 explore → propose → apply 是連續做的，中間忘了在 propose 後 commit。建議的習慣：

```
/opsx:explore   → 不產出文件，不需要 commit
/opsx:propose   → commit 規劃文件
/opsx:apply     → commit 實作程式碼
/opsx:archive   → commit 歸檔結果
```

每個 OpenSpec 指令完成後就 commit 一次，保持歷史清晰。

## 第四輪：精細流程（/opsx:new + /opsx:continue）

這一輪體驗擴充指令的精細控制流程，與 `/opsx:propose` 的一次到位做比較。

### `/opsx:propose` vs `/opsx:new` + `/opsx:continue`

| 方式 | 流程 | 適合場景 |
|------|------|----------|
| `/opsx:propose` | 一次產出所有文件 | 需求明確，想快速開始 |
| `/opsx:new` + `/opsx:continue` | 逐步產出，每步可審閱 | 需求需要推敲，想逐步確認 |

**關係**：`/opsx:propose` = `/opsx:new` + `/opsx:ff`（fast-forward）的合體。

### 精細流程步驟

```
/opsx:new add-favorites       → 建立目錄（只有 .openspec.yaml）
/opsx:continue                → 產出 proposal.md（1/4 artifacts）
  ↓ 審閱 proposal，滿意後繼續
/opsx:continue                → 產出 design.md（2/4 artifacts）
  ↓ 審閱 design，滿意後繼續
/opsx:continue                → 產出 specs/（3/4 artifacts，3 個檔案）
  ↓ 審閱 specs，滿意後繼續
/opsx:continue                → 產出 tasks.md（4/4 artifacts）
  ↓ 全部完成，可以 apply
/opsx:apply                   → 實作
/opsx:archive                 → 歸檔
```

### `/opsx:new` 的初始回應

執行 `/opsx:new <name>` 後，會顯示：
- 目前進度（0/4 artifacts complete）
- Artifact 依賴序列（proposal → design + specs → tasks）
- 第一個 artifact 的模板結構提示
- 提示你用 `/opsx:continue` 繼續

### `/opsx:continue` 的行為

- 每次只產出**一個** artifact
- 產出後顯示進度和已解鎖的下一個 artifact
- 如果是 specs，會一次產出所有相關的 spec 檔案（算一個 artifact）
- 也會出現互動選項（跟 propose 類似），選 **Type something** 貼上自訂描述

### 練習功能：書籤加入「我的最愛」

簡單的功能，全部都是 Modified capabilities（bookmark-crud、bookmark-search、dashboard），沒有新的 capability。

提供的描述：
```
書籤加入「我的最愛」功能。書籤可以標記/取消標記為最愛（Favorite），
書籤列表可以篩選只看最愛的書籤。儀表板顯示最愛書籤數量。
```

結果：13 個任務、5 個群組，規模比前幾輪更小。

## 完整 Commit 歷程

| 順序 | Commit 訊息 | 內容 |
|------|------------|------|
| 1 | `chore(openspec): initialize project and propose bookmark-manager change` | openspec init + /opsx:propose |
| 2 | `feat(backend): implement ASP.NET Core 8 Web API` | 後端完整專案 |
| 3 | `feat(frontend): implement React 18 SPA with Vite + TypeScript + Tailwind` | 前端完整專案 |
| 4 | `chore(openspec): mark all 34 tasks complete for bookmark-manager` | tasks.md 勾選狀態更新 |
| 5 | `chore(openspec): archive bookmark-manager and sync specs to main` | 歸檔 + 5 個 specs 同步 |
| 6 | `chore(openspec): propose add-collections change` | 收藏夾功能規劃（1 new + 3 modified） |
| 7 | `feat: add collections feature for bookmark grouping` | 收藏夾功能實作 |
| 8 | `chore(openspec): archive add-collections and sync specs to main` | 歸檔 + specs 合併 |
| 9 | `chore(openspec): propose add-public-sharing change` | 公開分享功能規劃（來自 explore 討論） |
| 10 | `feat: add public sharing for collections via token links` | 公開分享功能實作 |
| 11 | `chore(openspec): archive add-public-sharing and sync specs to main` | 歸檔 + specs 同步 |
| 12 | `chore(openspec): add extended workflow commands and skills` | 8 個擴充指令的定義檔 |
| 13 | `chore(openspec): propose add-favorites change via new + continue` | 精細流程產出的規劃文件 |
| 14 | `feat: add favorite bookmarks with star toggle and filter` | 我的最愛功能實作 |
| 15 | `chore(openspec): archive add-favorites and sync specs to main` | 歸檔 + specs 同步 |

## 其他注意事項

### .gitignore

`.claude/settings.local.json` 是 Claude Code 的本地權限設定，不需要版控。如果已經被追蹤過，需要：

```bash
echo ".claude/settings.local.json" >> .gitignore
git rm --cached .claude/settings.local.json
```

`git rm --cached` 只從 git 追蹤移除，不會刪除實際檔案。

## 安裝更多 OpenSpec 指令

### 預設指令（core profile）

安裝 OpenSpec 後預設只有 4 個指令：`/opsx:propose`、`/opsx:explore`、`/opsx:apply`、`/opsx:archive`。

### 擴充指令

OpenSpec 內建更多 workflow 模板，但 `openspec config profile` 目前只有 `core` 一個 preset。需要手動設定：

**步驟 1：修改全域設定**

設定檔位置：`C:\Users\<username>\AppData\Roaming\openspec\config.json`

在 `workflows` 陣列中加入需要的 workflow：

```json
{
  "featureFlags": {},
  "profile": "core",
  "delivery": "both",
  "workflows": [
    "propose", "explore", "apply", "archive",
    "new", "continue", "ff", "verify",
    "sync", "bulk-archive", "onboard", "feedback"
  ]
}
```

**步驟 2：重新產生指令檔案**

```bash
openspec update --force
```

> **注意**：v1.2.0 的 `openspec update` 可能不會自動產生新增 workflow 的指令檔案。如果重啟 Claude Code 後仍然看不到新指令，需要手動從 OpenSpec 的模板產生 skill 和 command 檔案到 `.claude/skills/` 和 `.claude/commands/opsx/`。

**步驟 3：重啟 Claude Code**

關掉再開 Claude Code CLI，讓它重新載入指令定義。

### 擴充指令一覽

| 指令 | 用途 | 使用時機 |
|------|------|----------|
| `/opsx:new` | 只建立 change 目錄，不產出文件 | 想手動逐步建立 artifact 時 |
| `/opsx:continue` | 繼續建立下一個 artifact | 搭配 `/opsx:new` 使用，逐步推進 |
| `/opsx:ff` | Fast-forward：一次產出所有規劃文件 | 對已有的 change 補齊文件 |
| `/opsx:verify` | 驗證實作是否符合規格 | archive 之前檢查完整性 |
| `/opsx:sync` | 同步 specs 到主規格庫（不 archive） | 只想更新 specs，不歸檔 |
| `/opsx:bulk-archive` | 一次歸檔多個 changes | 有多個並行 change 完成時 |
| `/opsx:onboard` | 引導式新手教學 | 新成員學習 OpenSpec 時 |
| `/opsx:feedback` | 向 OpenSpec 提交回饋 | 遇到問題或有建議時 |

### Core vs 擴充指令的關係

```
Core（快速流程）：
  /opsx:explore → /opsx:propose → /opsx:apply → /opsx:archive

擴充（精細控制）：
  /opsx:explore → /opsx:new → /opsx:continue（逐步）→ /opsx:apply → /opsx:verify → /opsx:archive
                              /opsx:ff（一次產出）
```

- `/opsx:propose` = `/opsx:new` + `/opsx:ff` 的合體（建立 change + 一次產出所有文件）
- 擴充指令讓你可以更精細地控制每一步

## 建議的 Session 分工模式

| Session | 用途 | 模型建議 |
|---------|------|----------|
| 教學 Session | 討論需求、審閱文件、學習 OpenSpec | Opus |
| 開發 Session | 執行 `/opsx:propose`、`/opsx:apply` 等 | Opus |
| 翻譯 Session（可選）| 將英文文件翻譯為中文供團隊閱讀 | Sonnet / Haiku |

**為什麼 OpenSpec 文件用英文：**
- AI 讀英文效果最好
- `SHALL`、`WHEN/THEN` 是規格語言的標準慣例
- 團隊需要中文版時，另開翻譯 Session 處理，避免雙語維護的不一致風險

## 下一步

- [x] 執行 `/opsx:propose` 產出規劃文件
- [x] 執行 `/opsx:apply` 實作所有任務
- [x] 驗證前後端功能正常
- [x] 執行 `/opsx:archive` 歸檔並同步規格
- [x] 在既有專案上新增功能（體驗 Modified Capabilities 流程）
- [x] 體驗 `/opsx:explore` 探索模式完整流程（Explore → Propose → Apply → Archive）
- [x] 安裝更多 OpenSpec 指令
- [x] 體驗擴充指令（`/opsx:new` + `/opsx:continue` 精細流程）
