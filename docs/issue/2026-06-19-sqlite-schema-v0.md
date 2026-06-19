---
title: SQLite で graph-shaped スキーマ v0 を切る (Phase 1 試作の永続化)
status: open
category: design
created: 2026-06-19T13:18:38+09:00
last_read:
open_entered: 2026-06-19T13:18:38+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by: prepare-eval-question-set
origin: 自リポ TODO (2026-06-19 設計セッションからの引き継ぎ)
---

# SQLite で graph-shaped スキーマ v0 を切る (Phase 1 試作の永続化)

## 概要

nandakke Phase 1 試作の永続化を SQLite で実装する。codex の独立レビュー (2026-06-19) で「Phase 1 は SQLite で始める、ただしスキーマは最初から graph-shaped に」と提案され、これを採用。理由は「索引思想が悪い」vs「DB が重かった (= Kùzu)」を分離するため。

## 背景

- 2026-06-19 設計セッションで永続化 A〜G を検討し C (SQLite 正規化) を本命に確定 (詳細: `docs/journal/2026-06-19-nandakke-design-session.md`)
- 当初「graph DB は too much」と Claude が評価したが議論を経て「nandakke の要件 (chain / cross / cycle / link kind 拡張 / 全部繋がる前提) は graph DB の本流ユースケース」と再評価
- codex 提案: SQLite で graph-shaped スキーマ (= 後で Kùzu 等の embedded graph DB に lossless 移行できる構造)

## 受け入れ条件

- [ ] `topics` 表 (id, sid NULL, repo NULL, domain NOT NULL, summary, body, stage, landing, confidence, created_at, updated_at, last_mention_at)
- [ ] `evidence` 表 (id, topic_id FK, kind, ref, sid NULL, repo NULL, inserted_at) — VCS は kind='vcs' 統一、ref 形式で jj/git 自動判別
- [ ] `topic_links` 表 (src_topic_id FK, kind, dst_ref, inserted_at)
- [ ] 3 軸スキーマ: `stage` (議論成熟度) / `landing` (着地状況) / `confidence` (証跡確度)
- [ ] link kind は最小 6 個 (`causes / depends / solves / contains / supersedes / related`) から始める
- [ ] domain は単一値 (dev / life / creative / meta / misc)
- [ ] recursive CTE で chain 再構成 / cycle 検出が動く (= visited set + depth limit)
- [ ] CLI で topic insert / evidence insert / topic_links insert ができる

## 棚上げ (= まだ実装しない)

- Kùzu への移行 (= SQLite で辛いと判明したら)
- link kind の細分化 (= 6 個で足りないと判明したら)
- temporal validity / 削除設計 / プライバシー境界 (= codex 指摘の盲点だが Phase 1 では棚上げ)

## 解決時の記録先

- 設計判断を伴う: decisions/DR-0004-sqlite-graph-schema.md (候補)
- 実装は別ファイル (= `src/` or `db/migrations/` 等、構造は別途決定)
