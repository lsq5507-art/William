# William

本分支是 **Little Paw ux-hotfix-web v0.20**（F1–F3）的可回滚快照。

- 分支：`release/little-paw-ux-hotfix-web-v0.20`
- 标签：`lp-ux-hotfix-web-v0.20`
- 线上：https://littlepaw.pet · https://little-paw-prod.web.app
- 回滚：`git checkout lp-ux-hotfix-web-v0.20`

源码在 `LittlePaw/`。这一支从 `cursor/add-littlepaw-flutter-9ca0` 拉出，保留 box 重建基线提交，再叠上 v0.20，不改写那条旧分支。

## 运行

```bash
cd LittlePaw && flutter pub get && flutter run -d chrome
```
