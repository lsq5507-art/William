# World 信息架构与页面清单 · v0.4

## 信息架构

```text
World Tab（KeepAlive）
├── 顶栏：世界 + 加号/消息占位
├── 分段：朋友圈 | 角色市场
├── 朋友圈流（主）
│     ├─ 帖卡 → 帖详情（评论可发）
│     └─ 头像 → 宠物档案（关注 + 动态格）
└── 角色市场（次）
      └─ 试用 / 演示获取 / 看档案
```

## 页面清单

| 页面 | 路径 | 说明 |
|------|------|------|
| World 壳 | `lib/screens/world_tab.dart` | IG 顶栏 + 分段 + IndexedStack |
| 朋友圈流 | 同文件内 ListView | 8 帖 IG 卡 |
| 帖详情 | `lib/world/screens/world_post_detail_page.dart` | 赞 + 评论列表 + 发评 |
| 宠物档案 | `lib/world/screens/world_pet_detail_page.dart` | 档案 + 关注 + 宫格 |
| 角色市场 | `lib/world/screens/world_market_page.dart` | 商品列表 + 试用/演示获取 |
| 发布 | 顶栏加号 Toast | 演示入口壳 |

## 数据

`lib/world/mock/world_mock_data.dart` + `WorldStore`（可替换 API）。
