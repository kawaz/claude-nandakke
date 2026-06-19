---
title: nandakke 利用時に `showThinkingSummaries: true` の有効化をチェック/促す機構
status: open
category: request
created: 2026-06-19T13:54:16+09:00
last_read:
open_entered: 2026-06-19T13:54:16+09:00
wip_entered:
blocked_entered:
pending_entered:
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:
close_reason:
blocked_by:
origin: 自リポ TODO (2026-06-19 設計セッション中の重要発見)
---

# nandakke 利用時に `showThinkingSummaries: true` の有効化をチェック/促す機構

## 概要

nandakke が読む CSA jsonl の `thinking` ブロックは、`~/.claude/settings.json` の
`"showThinkingSummaries": true` が無効だと **記録されるが内容が空文字列** になる。
この設定が無効の環境では nandakke の Phase 1 評価実験の前提が崩れ、T 型に依存した
索引化が機能不全になる。

利用前に必須要件として明示 + 実行時にチェックして警告/促進する仕組みを入れる。

## 背景

- 2026-03-21〜23 に kawaz が CSA 開発中に「timeline の T (thinking) が空っぽ」と気付き、
  `showThinkingSummaries: true` 追加で解決 (詳細: CSA セッション `e136fb81`、turn 6-8)
- デフォルトでは `false` (= thinking ブロックは jsonl に出るが本文が空)
- 2026-06-18 v3 60 並列実験の結論 (T 型優位、F 条件最多) は **この設定有効が暗黙の前提**
- 設定無効の環境では nandakke 全体の評価軸が崩れる (= 構造的に T 型情報が入手不能)

## 受け入れ条件

- [ ] README に Requirements として `showThinkingSummaries: true` の必須を明記
  (英訳ペア README-ja.md / README.md 両方)
- [ ] SessionStart hook (= プラグイン側のチェック機構) で `~/.claude/settings.json` を
      読み、`showThinkingSummaries` が `true` でない場合に nudge (= 一行警告 + 設定方法案内)
- [ ] DESIGN.md の前提条件セクションに記載
- [ ] 既存の `docs/journal/2026-06-18-phase1-trial-v3-matrix/SUMMARY-v3.md` の
      前提条件 caveat と相互参照 (= 既に追記済み)

## 解決時の記録先

- SessionStart hook 実装: `hooks/` 配下に新規 (Phase 1 試作の最小実装)
- 設定要件は DR を起こす候補 (= 「nandakke は thinking ブロック有効を必須前提とする」)
- README 修正と hook 実装は同時 (= ユーザに見せる窓口と機械的チェックを揃える)

## 関連

- v3 SUMMARY 注記: `docs/journal/2026-06-18-phase1-trial-v3-matrix/SUMMARY-v3.md`
- CSA 関連セッション: `e136fb81-4601-46be-a50e-c318a648be51` (`claude-session-analysis timeline e136fb81` で詳細)
- 設定ファイル参照: `~/.claude/settings.json` の `showThinkingSummaries` フィールド
