---
title: 評価質問セット 20 問の作成 (= Phase 1 評価の grand truth)
status: open
category: task
created: 2026-06-19T13:17:23+09:00
last_read:
open_entered: 2026-06-19T13:17:23+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: 自リポ TODO (2026-06-19 設計セッションからの引き継ぎ)
---

# 評価質問セット 20 問の作成 (= Phase 1 評価の grand truth)

## 概要

Phase 1 評価実験の質問セット (= grand truth) を 20 問固定で作る。これは件数指標を捨てて Q&A 正答率 + chain/cross/cycle 再構成テストで評価するため。codex の独立レビュー (2026-06-19) で「DB を選んだ後に質問を作ると、その DB に有利な評価になりがち」と指摘されたため、**質問セット先行が DB 選定より先**。

## 背景

- 2026-06-19 設計セッションで Phase 1 評価軸を「件数」から「Q&A 正答率 + chain/cross/cycle」に転換 (詳細: `docs/journal/2026-06-19-nandakke-design-session.md`)
- kawaz 自身が出した grand truth 例 3 種 (chain: 連絡帳→classroom-monitor / cross: cache-warden ↔ classroom-monitor / cycle: nandakke ↔ 60 本テスト ↔ local-issue) を素材にする
- ただし「3 つだけだと過学習」 (codex 指摘) なので blind な過去セッション (kawaz/Claude 両者が議論経緯を知らない素材) を混ぜる

## 受け入れ条件

- [ ] chain 再構成テスト用の問が含まれる (= 起点から完了まで辿れるか)
- [ ] cross-link 検出テスト用の問が含まれる (= 未解決と既存解を結べるか)
- [ ] cycle 検出テスト用の問が含まれる (= ドッグフーディングループ再構成)
- [ ] blind 素材から抽出した問が含まれる (= 評価者汚染回避)
- [ ] 全 20 問を 1 ファイル (= `docs/research/2026-MM-DD-eval-question-set.md` 等) で固定
- [ ] 各問の正答 (kawaz が知っている事実) を別途 grand truth として記録

## 解決時の記録先

- 質問セット本体: `docs/research/` に固定
- 設計判断 (= なぜ 20 問か、blind 素材の選定基準等): DR を起こす
