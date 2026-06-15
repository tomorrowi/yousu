# 有速 APP — Codemagic 免费编译 + iPhone 安装指南

> 无需 $99 Apple Developer，免费把 Flutter APP 装到你的 iPhone 15 Pro Max

---

## 前置准备（一次性，5 分钟）

### 1. 注册 Codemagic 账号
- 打开 [codemagic.io](https://codemagic.io)
- 用 GitHub / GitLab 注册
- 免费额度：500 分钟/月，够你每天构建多次

### 2. 把代码推到 GitHub
```powershell
cd C:\Users\wangg\WorkBuddy\2026-06-15-11-14-47\yousu_flutter
git init
git add .
git commit -m "有速 APP Flutter 版"
# 在 GitHub 上创建仓库后：
git remote add origin https://github.com/你的用户名/yousu.git
git push -u origin main
```

### 3. 添加 iOS 平台支持
```powershell
cd C:\Users\wangg\WorkBuddy\2026-06-15-11-14-47\yousu_flutter
flutter create --platforms=ios .
```
这会生成 `ios/` 目录，别担心，不会覆盖你现有的代码。

---

## Codemagic 配置（3 步）

### Step 1：连接仓库
- Codemagic 后台 → Add Application → 选择你的 GitHub 仓库
- 它会自动检测到 `codemagic.yaml`

### Step 2：配置 Apple 签名（这步最关键）
- Codemagic → 你的 App → **Code signing**
- 选择 **"Automatic code signing"**
- 选择 **"Default provisioning profile type: Development"**（免费账号用 Development）
- 输入你的 **免费 Apple ID** 和密码

### Step 3：开始构建
- 回到 Builds → Start new build
- 选择 `ios-free-build` workflow
- 等 5-10 分钟

---

## IPA 装到 iPhone（2 种方式）

### 方式 A：扫码安装（推荐）
构建成功后 Codemagic 生成一个安装链接/二维码：
1. 下载 Codemagic 生成的 `.ipa` 文件
2. 用 [Diawi](https://www.diawi.com) 或 [Install On Air](https://installonair.com) 上传 IPA
3. 生成安装链接，iPhone 扫码即可安装

### 方式 B：AltStore 侧载（稳定）
1. Windows 装 [AltServer](https://altstore.io)
2. iPhone 装 AltStore（通过 AltServer 安装）
3. 把 IPA 拖到 AltStore → 安装

---

## 注意事项

| 提醒 | 说明 |
|---|---|
| **7 天重签** | 免费证书 7 天过期，过期后需重新构建+安装 |
| **3 个 APP 限制** | 免费账号同一 iPhone 最多侧载 3 个 APP |
| **首次信任** | 安装后：设置 → 通用 → VPN与设备管理 → 信任证书 |
| **构建 IP** | Codemagic 免费版用共享 Mac，排队可能 5-15 分钟 |

---

## 快速参考：重签流程

7 天后重新走一遍：
1. Codemagic → Start new build → `ios-free-build` → 等 10 分钟
2. 下载新 IPA → 上传 Diawi → 扫二维码 → 覆盖安装

---

## 遇到问题？

| 错误 | 解决 |
|---|---|
| `No iOS project found` | 忘了跑 `flutter create --platforms=ios .` |
| `Provisioning profile expired` | 7 天到了，重新构建 |
| `App not installed` | iPhone 设置 → 通用 → VPN与设备管理 → 信任证书 |
| `Unable to install` | 手机存储满了 / 已有同名 APP 先卸载旧版 |
