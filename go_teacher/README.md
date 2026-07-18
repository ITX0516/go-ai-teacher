# 围棋AI老师 - 后端服务

基于 Go + KataGo + DeepSeek AI 的围棋教学平台后端。

## 功能特性

- AI 对弈（多难度级别）
- 实时棋局分析（胜率、目差、推荐走法）
- DeepSeek AI 棋理讲解
- 死活题/定式训练题库
- 棋谱复盘分析
- SGF 棋谱导出

## 技术栈

- Go 1.25+
- Gin Web 框架
- KataGo 围棋引擎
- DeepSeek (DeepSeek) AI 大模型

## 快速开始

```bash
cd go_teacher
go mod tidy
go run cmd/server/main.go
```

服务启动在 `http://localhost:8080`

## API 接口

### 游戏相关

- `POST /api/games/:id` - 创建新对局
- `GET /api/games/:id` - 获取棋局状态
- `POST /api/games/:id/move` - 落子
- `POST /api/games/:id/ai-move` - AI 走棋
- `POST /api/games/:id/undo` - 悔棋
- `GET /api/games/:id/analyze` - 分析当前局面
- `GET /api/games/:id/sgf` - 导出 SGF
- `POST /api/games/:id/explain` - DeepSeek 讲解走子
- `POST /api/games/:id/ask` - 向 AI 提问

### 题库相关

- `GET /api/puzzles` - 获取题目列表
- `GET /api/puzzles/:id` - 获取题目详情
- `POST /api/puzzles/:id/check` - 检查答案

## 环境变量

```env
PORT=8080
DEEPSEEK_API_KEY=your_deepseek_api_key
DEEPSEEK_API_URL=https://api.deepseek.cn/v1/chat/completions
KATAGO_PATH=./katago/katago
KATAGO_MODEL=./katago/model.bin.gz
```
