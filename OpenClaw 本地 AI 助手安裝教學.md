# OpenClaw 本地 AI 助手安裝教學

> OpenClaw 是一個開源的個人 AI 助手，可在本地運行，支援透過 Ollama 接本地模型，資料不離開你的電腦。
> 官方 GitHub：https://github.com/openclaw/openclaw

## 環境需求

| 項目 | 需求 |
|------|------|
| OS | Windows / macOS / Linux |
| Node.js | ≥ 22 |
| RAM | 8GB 以上（跑 7B 模型建議 16GB+） |
| GPU | 非必要，CPU 可跑小模型 |

## 一、安裝 Ollama（本地模型運行環境）

```bash
winget install Ollama.Ollama --source winget
```

安裝完成後確認：

```bash
ollama --version
```

## 二、安裝 OpenClaw

```bash
npm install -g openclaw@latest
```

確認安裝：

```bash
openclaw --version
```

## 三、拉取本地模型

依據硬體選擇適合的模型：

| 模型 | 大小 | 適合硬體 |
|------|------|----------|
| `qwen2.5:1.5b` | ~1 GB | 入門 / 低階硬體 |
| `qwen2.5:7b` | ~4.7 GB | i5+ / 16GB RAM（推薦） |
| `qwen2.5:14b` | ~9 GB | i7+ / 32GB RAM |

```bash
ollama pull qwen2.5:7b
```

確認已下載的模型：

```bash
ollama list
```

## 四、設定 OpenClaw 接 Ollama

```bash
openclaw config set models.providers.ollama.apiKey "ollama-local"
openclaw config set models.providers.ollama.baseUrl "http://127.0.0.1:11434/v1"
openclaw config set models.providers.ollama.api "openai-responses"
```

設定說明：

- `apiKey`：任意值即可，Ollama 不需要真正的 key
- `baseUrl`：Ollama 本地 API 位址，**必須加 `/v1` 後綴**
- `api`：必須設為 `openai-responses` 或 `openai-completions`

## 五、執行 Onboarding 設定精靈

```bash
openclaw onboard
```

互動式設定建議選項：

| 步驟 | 建議選擇 |
|------|----------|
| Onboarding mode | **QuickStart** |
| Config handling | **Use existing values**（已設定好 Ollama） |
| Model/auth provider | **Ollama** |
| Ollama base URL | `http://127.0.0.1:11434`（預設值，直接 Enter） |
| Ollama mode | **Local** |
| Default model | 選擇你拉取的模型，如 `ollama/qwen2.5:7b` |
| Select channel | **Skip for now**（之後再接通訊平台） |
| Search provider | **Skip for now** |
| Configure skills | **No** |
| Enable hooks | **Skip for now** |

## 六、啟動 Gateway

安裝 Gateway 服務並啟動：

```bash
openclaw gateway install
openclaw gateway
```

常用 Gateway 指令：

```bash
openclaw gateway status   # 查看狀態
openclaw gateway stop     # 停止服務
openclaw gateway          # 啟動服務
```

啟動後會自動開啟瀏覽器，存取網頁介面：

```
http://127.0.0.1:18789/#token=<你的token>
```

## 七、後續調整

### 更換模型

```bash
# 拉取新模型
ollama pull qwen2.5:14b

# 在 OpenClaw 設定中更改預設模型
openclaw configure
```

### 接雲端模型

如果本地模型不夠聰明，可以在 `openclaw configure` 中設定雲端 API（Claude、OpenAI 等），需要對應的 API key。

### 接通訊平台

重新執行 `openclaw configure`，選擇要接的平台（Telegram、Discord、LINE 等）並填入對應的 Bot Token。

## 參考資料

- [OpenClaw 官方文件](https://docs.openclaw.ai/)
- [OpenClaw Ollama 整合](https://docs.openclaw.ai/providers/ollama)
- [Ollama 官網](https://ollama.com/)
