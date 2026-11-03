# Little Paw（LP-DEV-01）

> **基线声明：box 重建基线，非原 v12 字节级副本。**  
> 本仓库在 Linux box 上以 `flutter create` 重建，按 PRD Must M1–M7 + LP-D-01 实现**最小可运行壳**。  
> **不要**声称与原 Mac 路径 `flutter_app` / APK v12 同源；不依赖用户本机路径。

## 平台

| 平台 | 状态 |
|------|------|
| Web | 优先；`flutter build web` |
| Android | 工程保留；box 若无 Android SDK 则不强制出 APK |
| iOS | 工程配置保留；Linux box **无**官方 iOS 真机构建 |

## 经济数字（只读真源，对齐 handoff）

- 免费：每 UTC 日 **2** 动态 / **10** 回复；终身 **3** 次图片体验  
- 会员展示：每日 **4** / **40**；30 日 **30** 图  
- 价目假设：月 **9.90** / 年 **59** / 卡 **9.90** / 册 **19.90**  
- **禁止**：真支付、真模型 API、把模拟购记入付费成功

## 本地运行

```bash
export PATH="/home/box/flutter/bin:$PATH"
cd /workspace/little-paw
flutter pub get
flutter analyze
flutter test
flutter run -d chrome          # 或 web-server
flutter build web --release
```

## 演示脚本（G.1）

1. 欢迎边界句 → 创建（现实/想念/虚构）→ SCR-11 确认 → 开场 3 条（不可跳过进空 Feed）  
2. Feed 首评 → 模拟回应 → Toast  
3. 触顶条「明天再来看它」+「看看正式方案」  
4. 正式意愿提交 → 会员状态不变；导出见 `pay_intent_choice`  
5. Profile 演示商店 → `simulate_purchase_*` 分轨  

交付说明见：`/workspace/staff-system/outputs/开发/LP-DEV-01-delivery.md`
