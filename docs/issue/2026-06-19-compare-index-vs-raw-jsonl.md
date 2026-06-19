---
title: 質問 20 問への正答率を「索引あり (SQLite) vs 索引なし (jsonl 直渡し)」で比較する (= Phase 1 第一段検証)
status: open
category: task
created: 2026-06-19T13:21:17+09:00
last_read:
open_entered: 2026-06-19T13:21:17+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
  - prepare-eval-question-set
  - sqlite-schema-v0
  - register-this-session-as-grandtruth
origin: 自リポ TODO (2026-06-19 設計セッションからの引き継ぎ)
---

# 質問 20 問への正答率を「索引あり (SQLite) vs 索引なし (jsonl 直渡し)」で比較する (= Phase 1 第一段検証)

## 概要

評価質問セット 20 問を、3 条件に渡して正答率と所要 token を比較する:

1. **No-index**: 生 jsonl だけ渡して回答 (= ベースライン)
2. **Index-only**: nandakke SQLite 索引だけ渡して回答 (= 索引が当たり付けに使えるか)
3. **Index + drill-down**: 索引で当たり付け → CSA で該当 turn を読んで回答 (= 本番運用形)

これが Phase 1 が valid か否かの第一段検証 = DR-0001 §YAGNI の「第一段が無価値なら以降は土台がない」のチェックポイント。

## 背景

- 2026-06-19 設計セッションで Phase 1 評価軸を確定 (詳細: `docs/journal/2026-06-19-nandakke-design-session.md`)
- codex 提案の追加指標: false positive 率 / 根拠到達性 / 復元不能率 / 更新コスト / **inter-rater reliability (= 別 Claude が同じ link を付けるか)** / staleness 検出
- 評価者汚染回避のため、blind なセッション素材で別 Claude セッションに回答させる

## 受け入れ条件

- [ ] 3 条件 (No-index / Index-only / Index + drill-down) で 20 問を回答
- [ ] 別 Claude セッションに依頼 (= 評価者汚染回避、kawaz と現セッションの Claude は議論経緯を知っているため不適格)
- [ ] 正答率の比較表を出す
- [ ] 所要 token (= 各条件で消費したコンテキスト量) を測る
- [ ] inter-rater reliability の測定 (= 同じ条件で別の Claude が同じ link を付けるかを確認、最低 2 回試行)
- [ ] Phase 1 が valid な検証ポイント (= 「Index-only が No-index と同等以上の正答率」+ 「Index + drill-down で大幅な token 削減」) を満たすか判定

## 解決時の記録先

- 評価結果は `docs/findings/` に確定事実として記録
- 結論 (Phase 1 が valid / not valid) は DR を起こす (= DR-000X 候補)
- valid なら Phase 2 への進行判断
- not valid なら nandakke 全体の方針再考
