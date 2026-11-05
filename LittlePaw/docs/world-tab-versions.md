# World Tab 版本记录

约定：每次 World 改动追加一行并递增版本号；设计稿标题与 Dart 文件头同步。

| 版本 | 日期（Asia/Shanghai） | 改动摘要 | 关联设计稿 | 关键文件 |
|------|----------------------|----------|------------|----------|
| v0.1 | 2026-11-03 前 | 占位页（原 World placeholder） | — | `lib/screens/world_tab.dart`（占位） |
| v0.2 | 2026-11-03 | 角色市场 + Instagram 风（规划态；合并进 v0.3/v0.4） | `LP-D-05` 早期稿 | （未单独长期驻留） |
| v0.3 | 2026-11-03 | 宠物朋友圈流 + 高质量本地图 + IG 视觉（中间目标） | `LP-D-05` | feed 卡 / assets |
| v0.4 | 2026-11-03 | 独立子项目完整度：需求/IA、mock 仓库、朋友圈+市场+详情、赞评关注、KeepAlive、文档、部署 `?v=world-v0.4` | `outputs/设计/LP-D-05-world-character-market.md` | `lib/world/**`, `lib/screens/world_tab.dart`, `assets/world_feed/`, `docs/world/**` |
| **v0.5** | **2026-11-03** | **产品表面去演示：去掉 Profile 演示商店/铺满开关、意向/额度/市场/顶栏/FAB 的演示·占位文案；默认关闭 feed demo fill；正式产品语气** | `outputs/产品/LP-P-05-product-surface-no-demo.md` | `lib/l10n/strings.dart`, `profile_tab.dart`, `intent_sheet.dart`, `world_market_page.dart`, `space_store.dart`, tests |

体验 URL 约定：`https://lsq5507-art.github.io/William/?v=world-v0.5`  
本地：`http://127.0.0.1:8080/William/?v=world-v0.5`
