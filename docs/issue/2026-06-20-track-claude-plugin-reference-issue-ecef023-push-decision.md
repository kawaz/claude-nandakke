---
title: claude-plugin-reference へ起票した issue (ecef023) の push 判断追跡
status: pending-sublimation
category: task
created: 2026-06-20T00:00:31+09:00
last_read:
open_entered:
wip_entered:
blocked_entered:
pending_entered: 2026-06-20T00:00:31+09:00
discarded_entered:
resolved_entered:
discard_reason:
pending_reason:    # ["pending","push/撤回/書き換えの判断待ち"]
close_reason:
blocked_by:
origin: 自リポ TODO (2026-06-19 設計セッション中の外部起票の push 判断追跡)
---

# claude-plugin-reference へ起票した issue (ecef023) の push 判断追跡

## 概要

2026-06-19 のセッションで claude-plugin-reference リポへ improvement issue を起票
(クロスプロジェクト起票、ローカル commit `ecef023`)。push はしていない。

push するか / 別形に書き換えるか / 撤回するかの判断を保留状態として記録、判断確定したら本 issue を close。

## 背景

2026-06-19 nandakke 設計セッション中、AI (Claude Opus 4.7) が reference 本体を読まずに議論を進める誤推測パターンが複数回発生 (= `_` prefix の hidden command、Dynamic Context Injection など)。kawaz の指摘で reference 本体を確認したら、既に標準サポートされている機能を「未サポート / 検証要」と AI が誤判断していたことが判明。

これを受けて SessionStart hook をプロジェクト構造対応で強化する improvement 案を起票:
- 案 A: SessionStart hook で `/Users/kawaz/.local/share/repos/github.com/kawaz/claude-nandakke/main/{skills,commands,hooks,agents}` の有無を grep して関連 reference を「必読」マーク
- 案 B: SKILL.md 内に Dynamic Context Injection で動的優先度表示

起票ファイル: kawaz/claude-plugin-reference `docs/issue/2026-06-19-enhance-sessionstart-with-project-aware-must-reads.md`
ローカル commit: `ecef023`

## 起票後の reference 側の動き (= 一部解決済み)

reload-plugins 後の確認で、reference リポに `64031c9 docs(skill,commands): 配置軸を invoke 性質 (実行型 vs ガイド型) で整理 + audience 明示 + permission ガード対策` という commit が独立に入っていた。

これにより:
- 「commands と skills は両者同一機構、両方読む」原則が構造化された (= AI が一方だけ読む問題は緩和)
- 起票元の nandakke project memory `feedback_plugin_reference_reading_pairs.md` は重複として削除済み

ただし起票した「プロジェクト構造に応じた必読マーク」 (= 案 A/B) は **まだ未着手**。`ecef023` 自体は reference リポにローカル commit のみで未 push。

## 判断候補

### (a) push する
- claude-plugin-reference 側に正式に improvement 提案として届く
- kawaz 自身が当事者なので「自リポへの非同期メッセージ」として届ける意味は薄い (= 既に内容を把握済み)

### (b) 撤回 (= jj abandon / commit revert) する
- `64031c9` で関連改善が独立に入った
- 案 A/B 自体が冗長になった可能性 → 撤回が筋

### (c) 内容を再評価して別形に書き換え
- `64031c9` 後でも残る課題 (= 案 A の「プロジェクト構造別必読指定」) を絞って再起票
- 案 B (Dynamic Context Injection) は既に SKILL.md で使われている (例: `` ` \! `cat ${CLAUDE_SKILL_DIR}/last-verified.txt` `` ) ので、必読マークへの拡張だけが本質

## 受け入れ条件

- [ ] (a)(b)(c) のいずれかを判断
- [ ] push する場合: `(cd ~/.local/share/repos/github.com/kawaz/claude-plugin-reference/main && just push)` を実行
- [ ] 撤回する場合: jj abandon で commit を捨てる
- [ ] 書き換える場合: 当該 issue を local-issue:update で修正 → push

## 解決時の記録先

- 単純な撤回: 記録不要 (commit message で足りる)
- 書き換え → push に発展した場合: journal/2026-06-19-nandakke-design-session.md に追記

## 関連

- 起票 commit: `ecef023` (claude-plugin-reference リポ)
- reference 側の独立対応: `64031c9 docs(skill,commands): 配置軸を invoke 性質で整理...`
- 起票元議論: `docs/journal/2026-06-19-nandakke-design-session.md`
- nandakke memory: `feedback_plugin_reference_reading_pairs.md` は削除済 (重複)
