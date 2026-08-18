# Trinketer - 饰品人

> 以撒的结合：忏悔 (The Binding of Isaac: Repentance) 角色 Mod

## 简介

Trinketer（饰品人）是一个全新的自定义角色，围绕「饰品」与「咕噜药」构建独特的玩法机制。

## 角色特性

### 初始物品
- **咕噜药 (Gulp!)** — 初始药丸
- **随机普通饰品** — 初始饰品

### 核心机制

1. **药丸转换**：所有途径生成的药丸，有 **50% 概率**在生成时变为咕噜药
2. **道具品质拦截**：
   - **0 级道具**：100% 被阻止，转化为 **2 个随机饰品**
   - **1 级道具**：25% 概率被阻止，转化为 **3 个随机饰品**
3. **长子名分 (Birthright)**：
   - 使用咕噜药时，若当前饰品存在金色版本 → 先变为金色版本再吞下
   - 若当前饰品已是金色饰品 → 在地面生成 1 个随机饰品

## 兼容性

- 适配：以撒的结合：忏悔 (Repentance)
- 支持 EID (External Item Descriptions) 描述显示
- 支持多人游戏

## 安装方法

1. 下载本仓库的全部文件
2. 将文件夹放入以撒的结合 Mod 目录：
   - Windows: `Documents\My Games\Binding of Isaac Repentance\mods\`
3. 在游戏主菜单的 **Mods** 中启用 Trinketer

## 文件结构

```
Trinketer/
├── main.lua              # 主逻辑脚本
├── metadata.xml          # Mod 元数据
├── content/
│   └── players.xml       # 角色定义
└── resources/
    └── stringtable.sta   # 多语言字符串表
```

## 作者

- **Yanloo** — 创意设计与测试

---

> **声明：该 Mod 代码部分通过豆包 AI 制作。**
> 
> Code generated with the assistance of Doubao AI.