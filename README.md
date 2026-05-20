# 安心记账

安心记账是一款基于 OpenHarmony 5.0 / API 19 开发的原生智能记账应用，使用 ArkTS、ArkUI、Preferences 本地持久化和状态管理能力实现，面向个人日常收支记录、预算控制和消费分析场景。

## 功能特性

- 用户登录注册、表单校验和登录态管理
- 本地账单新增、删除、修改、查询
- 收入/支出类型选择、分类管理、金额、备注和日期记录
- 首页月度收入、支出、结余实时统计
- 月预算、分类预算设置与预算超额预警
- 收支报表、分类占比和近七日趋势展示
- 个人中心、头像昵称设置、退出登录
- 本地账单数据清空与导出
- 接入 DeepSeek API，实现 AI 自然语言记账，支持对话式账单增删改查

## 技术栈

- OpenHarmony 5.0 / API 19
- DevEco Studio 5.1.1
- ArkTS
- ArkUI
- Preferences 本地持久化
- OpenHarmony 原生状态管理
- DeepSeek Chat Completions API

## 项目结构

```text
universityCompetition/
├── AppScope/
├── entry/
│   ├── src/main/ets/
│   │   ├── common/
│   │   ├── entryability/
│   │   ├── model/
│   │   ├── pageComp/
│   │   ├── pages/
│   │   ├── repository/
│   │   ├── service/
│   │   ├── store/
│   │   ├── utils/
│   │   └── views/
│   └── src/main/resources/
├── build-profile.json5
├── hvigorfile.ts
└── oh-package.json5
```

## 运行说明

1. 使用 DevEco Studio 5.1.1 打开项目。
2. 确认 SDK 配置为 OpenHarmony / HarmonyOS API 19。
3. 同步依赖后选择 `entry` 模块运行。
4. 如需使用 AI 记账助手，请在应用内 AI 页面配置 DeepSeek API Key。

## 隐私说明

项目源码不包含任何 API Key。AI Key 由用户在应用内自行配置，并保存在本地持久化中。账单数据、预算数据和用户资料均以本地存储为主。
