# 围棋 AI 老师 (Go AI Teacher)

基于 **Flutter + Go + KataGo + Kimi AI** 的智能围棋教学平台。

## 项目结构

```
.
├── go_teacher/              # Go 后端服务
│   ├── cmd/server/          # 程序入口
│   ├── internal/
│   │   ├── config/          # 配置加载
│   │   ├── handlers/        # HTTP 处理器
│   │   ├── models/          # 数据模型（围棋规则引擎）
│   │   └── services/        # 业务逻辑
│   │       ├── game_service.go     # 游戏管理
│   │       ├── katago_service.go   # KataGo 引擎封装
│   │       ├── kimi_service.go     # Kimi AI 讲解
│   │       ├── puzzle_service.go   # 死活题库
│   │       └── user_service.go     # 用户与成就系统
│   ├── go.mod
│   └── README.md
│
├── go_teacher_flutter/      # Flutter 跨端前端
│   └── lib/
│       ├── main.dart        # 入口与底部导航
│       ├── models/          # 数据模型
│       ├── services/        # API 调用
│       ├── widgets/         # 公共组件（围棋棋盘等）
│       └── pages/           # 5 大页面
│           ├── home_page.dart       # 首页仪表盘
│           ├── play_page.dart       # AI 对弈
│           ├── puzzles_page.dart    # 死活题训练
│           ├── review_page.dart     # 棋谱复盘
│           └── courses_page.dart    # 分级课程
│
└── README.md
```

## 核心功能

- 🎮 **AI 对弈**：多难度级别（入门/业余/职业），实时胜率分析，悔棋功能
- 🧩 **死活题训练**：分类题库（死活/吃子/定式），AI 讲解，错题回顾
- 📊 **棋谱复盘**：胜率曲线、AI 推荐走法、手顺回放、整体复盘总结
- 📚 **分级课程**：从入门到高级，系统化学习路径
- 🤖 **Kimi AI 老师**：棋理讲解、走子点评、问答互动、复盘总结
- 🏆 **成就系统**：等级经验、连续打卡、9 个成就徽章

## 技术架构

```
┌─────────────────┐      HTTP/JSON       ┌──────────────────┐
│  Flutter 前端   │  ←─────────────────→ │   Go 后端服务    │
│  (跨端 App)     │                       │   (Gin 框架)     │
└─────────────────┘                       └────────┬─────────┘
                                                   │
                                          ┌────────┴─────────┐
                                          │                  │
                                          ▼                  ▼
                                   ┌──────────┐       ┌────────────┐
                                   │ KataGo   │       │  Kimi AI   │
                                   │ 围棋引擎 │       │  讲解引擎  │
                                   │ (量化)   │       │ (自然语言) │
                                   └──────────┘       └────────────┘
```

**KataGo** 负责计算量化数据（胜率、目差、最佳走法），
**Kimi** 把冰冷数字翻译成通俗易懂的棋理讲解。

## 快速开始

### 后端

```bash
cd go_teacher
cp .env.example .env  # 配置 KIMI_API_KEY
go mod tidy
go run cmd/server/main.go
# 服务启动在 http://localhost:8080
```

### 前端

```bash
cd go_teacher_flutter
flutter pub get
flutter run -d chrome   # Web 运行
```

## API 概览

| 接口 | 说明 |
|------|------|
| `POST /api/games/:id` | 创建对局 |
| `POST /api/games/:id/move` | 落子 |
| `POST /api/games/:id/ai-move` | AI 走棋 |
| `POST /api/games/:id/explain` | Kimi 讲解走子 |
| `POST /api/games/:id/ask` | 向 AI 提问 |
| `POST /api/games/summary` | 整局复盘总结 |
| `GET /api/puzzles` | 获取题目列表 |
| `POST /api/puzzles/:id/check` | 检查答案 |
| `GET /api/users/:id/progress` | 用户进度 |
| `GET /api/achievements` | 成就列表 |

## License

MIT
