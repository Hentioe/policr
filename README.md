# Policr Bot [![Build Status](https://github-ci.bluerain.io/api/badges/Hentioe/policr/status.svg)](https://github-ci.bluerain.io/Hentioe/policr)

即将成为 Telegram 平台最强大的审核机器人

## 使用

### 指令总览

| 名称               | 描述                 | 类型 | 详情 |
| :----------------- | :------------------- | :--: | :--: |
| `/ping`            | 存活测试             | 状态 |  略  |
| `/from`            | 设置来源调查         | 设置 |  略  |
| `/enable_examine`  | 启用审核             | 开关 |  略  |
| `/disable_examine` | 禁用审核             | 开关 |  略  |
| `/enable_from`     | 启用来源调查         | 开关 |  略  |
| `/disable_from`    | 禁用来源调查         | 开关 |  略  |
| `/torture_sec`     | 更新验证时间（秒）   | 设置 |  略  |
| `/torture_min`     | 更新验证时间（分钟） | 设置 |  略  |
| `/trust_admin`     | 信任管理员           | 开关 |  略  |
| `/distrust_admin`  | 不信任管理员         | 开关 |  略  |
| `/clean_mode`      | 干净模式             | 开关 |  略  |
| `/record_mode`     | 记录模式             | 开关 |  略  |

### 快速入门

作为群组创建者，在信任群管理的前提下，建议让管理员们帮忙干活

```
/trust_admin@policr_bot
```

为避免被垃圾帐号打扰，直接启用全部审核功能

```
/enable_examine@policr_bot
```

有些人反应很迟钝，默认验证时间 45 秒可能有点短

```
/torture_sec@policr_bot
```

群组正在四处宣传，很需要知晓如群成员来自何处

```
/from@policr_bot
```

怎么回事？机器人不干活嘞，检测它是否还活着

```
/ping@policr_bot
```

加群的人太多了，验证后的步骤消息能不能自动清理？

```
/clean_mode@policr_bot
```

机器人正在积极更新功能中……

## 需知

- 更多的详情请访问[官网](https://policr.bluerain.io)
- 务必关注社区频道掌握最新的功能更新通知：[PolicrBot Community](https://t.me/policr_community)
- 最佳的贡献方式是**反馈有价值的建议**，而不是试图提交代码
