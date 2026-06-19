---
title: 2026-06-19 設計セッション自体を grand truth として SQLite に手書き登録する
status: open
category: task
created: 2026-06-19T13:20:00+09:00
last_read:
open_entered: 2026-06-19T13:20:00+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by: sqlite-schema-v0, prepare-eval-question-set
origin: 自リポ TODO (2026-06-19 設計セッションからの引き継ぎ、自己 dogfood)
---

# 2026-06-19 設計セッション自体を grand truth として SQLite に手書き登録する

## 概要

2026-06-19 の nandakke 設計セッション自体が **cycle 例の生きた素材** なので、SQLite スキーマ v0 が完成したら手書きで topic を登録して第一段検証の grand truth にする。「自分の食う飯を自分で作る」。

## 背景

- 2026-06-19 設計セッションは「nandakke 構想 → 60 本テスト → 完了判定問題 surfaced → local-issue spawned → local-issue delivered → fed_back_to nandakke → 設計再検討」という cycle の構成要素
- 詳細: `docs/journal/2026-06-19-nandakke-design-session.md` の「このセッションの構造的位置付け」セクション
- chain 例 (連絡帳→classroom-monitor 7 topic) と cross 例 (cache-warden ↔ classroom-monitor) も同様に手書き登録する

## 受け入れ条件

- [ ] cycle 例の 7 topic 連鎖 (nandakke→60テスト→完了判定→local-issue 構想→local-issue 完成→fed_back→設計再検討) を topic として登録
- [ ] 各 topic 間の link を `spawned_during / fed_back_to / surfaced_problem / delivered` 等で記録 (= ただし最小 6 link kind の範囲で表現できるか検証する)
- [ ] domain は全て `meta` (= nandakke 自身の構築過程)
- [ ] evidence として CSA イベント ID (= このセッションの sid: 88abf7b1-17e6-4ade-a166-361876270cd1 の特定 turn) を記録
- [ ] chain 例 / cross 例も同様に手書き登録
- [ ] 評価質問セットの問のうち「nandakke の現仕様はどこから来た?」に正答できるか確認

## 解決時の記録先

- 登録した dataset は別ファイル (= `db/grand-truth-v0.sql` 等、構造は別途決定)
- 評価実験の経過は journal に

close 時はこのファイルを docs/issue/archive/ へ移動する(削除しない。経緯を DB として残す)。
