# Little Paw Firebase P0（执行中）

日期：2026-11-03 Asia/Shanghai  
账号：lsq5507@gmail.com（已授权）  
默认：游客可本地玩；绑定 Google 后云同步。Play Billing 本期不做。

## 步骤
1. Firebase CLI/MCP 登录（进行中）
2. 创建项目 `little-paw-prod`（若占用则 `little-paw-app`）
3. `firebase_init`：Auth(Google) + Firestore
4. 注册 Web/Android/iOS app，拉 SDK config
5. Flutter：`firebase_core` / `firebase_auth` / `cloud_firestore` / `google_sign_in`
6. SpaceStore：本地优先；登录后 upsert `users/{uid}/state`
7. Security rules：仅本人读写
8. analyze / test / build web

## 红线
- 模拟 IAP ≠ 真付费
- 密钥不进 git：`google-services.json` / options 走本地忽略或 CI 注入
