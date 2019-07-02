# Policr Bot [![Build Status](https://github-ci.bluerain.io/api/badges/Hentioe/policr/status.svg)](https://github-ci.bluerain.io/Hentioe/policr)

大概是 Telegram 平台最强大的审核机器人

## 介绍

本项目的设计原则是定制、专注和私有部署。核心审核功能完备且复杂，能应对各种意外情况，还有人性化的验证容错设计。

专注体现在不做不相干的功能，定制体现在提供友好的设置菜单和众多的可选项，并支持多种验证方式（之所以称之为最强大，这也是核心原因。如果不是，请打醒）。

**注意**：无论是官网还是本页面都可能是过时的，想知道最新功能请关注更新频道。

### 功能概括

PolicrBot 的主要作用和目的是排除潜在的加群机器人，它通过强制要求入群用户完成验证做到这一点。虽然并非本项目所期待的目的，但因为高定制性，也被用来提高入群门槛，设定专业问题。

由于高度抽象的设计，支持新的验证方式变得非常容易。本项目会考虑一切值得推荐的验证机制，但不会支持验证码（[原因请看这里](https://policr.bluerain.io#verification_code)）。

我们不会提供类似 `CNBlacklistR` 这种简单又不透明的黑名单功能。好消息是初版黑名单系统已经构思完成并在实现中，详情[看这里](https://github.com/Hentioe/policr/issues/20)。

### 开发技术

得益于原生语言 Crystal 的优势，机器人实例能以极低的成本高效率执行。编译完成后的二进制只有区区 4.9MB 大小，内存占用不超过 10MB，在保持低资源占用的同时能处理超高并发量的消息。

不同于很多使用 Python 编写的将处理逻辑都集中于一个文件的简单机器人，此项目源码有清晰的文件结构和良好的消息处理单元抽象，具备很高的扩展性和可维护性。能在不侵入已有功能代码的情况下进行扩展和定制。

## 使用&部署

**相关说明已经全部迁移到官网首页**，请访问[这里](https://policr.bluerain.io)。

## 加入我们

- [POLICR · 中文社区](https://t.me/policr_community)
- [POLICR · 更新通知](https://t.me/policr_changelog)
