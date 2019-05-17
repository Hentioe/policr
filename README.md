# Policr Bot [![Build Status](https://github-ci.bluerain.io/api/badges/Hentioe/policr/status.svg)](https://github-ci.bluerain.io/Hentioe/policr)

即将成为 Telegram 平台最强大的审核机器人

## 介绍

Policr 源自于单词 Polic(e)r，意为监察者。去 e 后结尾的 cr 对应了开发语言 Crystal 的缩写。

### 开发技术

不同于很多使用 Python 编写的简单机器人，本项目有清晰的代码结构和良好的处理单元抽象。可以被编译为原生执行的二进制文件，并且只有区区 3.5MB 大小。内存占用一般不会超过 10MB（如果消息并发量很高，会有增加）。

没有使用数据库中间件，利用了嵌入式数据库 RocksDB 储存设置和白名单。所以能非常简单的实施部署，并快速体验到它的极高性价比（超低占用+超高并发处理）。

同时，它还内置了一个 Web 服务，例如我们访问到的官网。有开发后台提供给管理员更强大的功能的想法，但还在计划中。

## 使用

### 部署指南

此部分暂时略过。

原因：为了保持高更新频率，我需要你们都使用此项目的官方实例 [PolicrBot](https://t.me/policr_bot)。并强烈建议每一个管理员都关注下面会提到的社区频道。

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
| `/custom`          | 定制验证问题         | 设置 |  略  |

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

群组正在四处宣传，很需要知晓入群成员来自何处

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

默认的验证方式太简单了，我想调整一下

```
/custom@policr_bot
```

机器人正在积极更新功能中……

## 需知

- 更多的详情请访问[官网](https://policr.bluerain.io)
- 务必关注社区频道掌握最新的功能更新通知：[PolicrBot Community](https://t.me/policr_community)
- 最佳的贡献方式是**反馈有价值的建议**，而不是试图提交代码

## TODO

- [x] 后台管理
  - [x] 登录页
  - [ ] 申请令牌
  - [ ] 自定义设置
- [x] 国际化支持
  - [x] 简体中文
  - [ ] 繁体中文
  - [ ] 英文
