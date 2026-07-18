# 围棋AI老师 - Flutter 前端

基于 Flutter 的跨端围棋教学应用，支持 Android、iOS、Web、桌面端。

## 功能特性

- 🎮 **AI 对弈**：多难度级别，实时分析，悔棋功能
- 🧩 **死活题训练**：分类题库，AI 讲解，错题回顾
- 📊 **棋谱复盘**：胜率曲线，AI 建议，手顺回放
- 📚 **分级课程**：从入门到高级，系统化学习
- 🤖 **Kimi AI 老师**：棋理讲解，问答互动，复盘总结
- 🏆 **成就系统**：等级经验，连续打卡，徽章收集

## 技术栈

- Flutter 3.x / Dart 3.x
- Provider 状态管理
- http 网络请求
- fl_chart 图表

## 快速开始

```bash
cd go_teacher_flutter
flutter pub get
flutter run -d chrome   # Web 运行
flutter run             # 移动端运行
```

## 项目结构

```
lib/
├── main.dart              # 入口文件
├── models/                # 数据模型
│   └── game_models.dart
├── services/              # 服务层
│   └── api_service.dart
├── widgets/               # 公共组件
│   └── go_board.dart      # 围棋棋盘组件
├── pages/                 # 页面
│   ├── home_page.dart     # 首页
│   ├── play_page.dart     # AI对弈
│   ├── puzzles_page.dart  # 死活题
│   ├── review_page.dart   # 复盘
│   └── courses_page.dart  # 课程
└── utils/                 # 工具类
```

## 后端接口

后端服务地址在 `lib/services/api_service.dart` 中配置：
- 本地开发默认：`http://10.0.2.2:8080` (Android 模拟器)
- Web 开发：`http://localhost:8080`

## 配置 Kimi AI

在后端 `.env` 文件中配置 `KIMI_API_KEY` 即可启用真实 AI 讲解。
未配置时使用演示模式的模拟回复。
