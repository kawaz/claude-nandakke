# Phase 1 素振り v2 (CSA 必須版) の比較

v1 (jq 直読 / user+assistant テキストのみ抽出 = TRU 相当) に対する **CSA `timeline` -t 指定なし (全 type) + `file-ops -d 1` 必須** での再走 3 件。短中長混在: 10 (46秒) / 07 (50分) / 03 (2 日)。

## 件数比較

| 題材 | v1 | v2 | 差分 | 増えたエントリの性格 |
|------|---|---|------|--------|
| 10 (nandakke prev) | 5 | 5 | ±0 | 件数同じだが **v1 の誤記が訂正** + 誤パス試行が事実化 |
| 07 (classroom-monitor) | 8 | 11 | +3 | buddy 経路分岐 / worktree→main cp 反映 / iMessage 本文テンプレ — 全部 Bash + file-ops 由来 |
| 03 (cmux-msg) | 15 | 20 | +5 | label 実装 / context: fork 検証 / ci.yml just-pin 削除 / justfile modernize / haiku+context:fork 適用 — 全部 file-ops/Bash 由来 |

短いセッション (10) では件数差ゼロ。中〜長 (07, 03) では **30〜40% 増加**。

## CSA で初めて拾えた情報の類型

10 / 07 / 03 の v2 から抽出。**共通して効いたのは下記 5 つ**:

### 1. F (File) / file-ops による「実装の独立検証」

v1 では「assistant が『実装した』と言った」だけが根拠だった。v2 では `file-ops -d 1` で Write/Edit の chronological JSONL が取れるので、

- 03: turn20 で SQLite 4 ファイルが実際に Write された → DR-0016 implemented の独立証跡
- 03: DR-0013 (ccmsg リネーム) は `package.json` への Write が **ない** → 「Accepted だが未実装」の否定証拠
- 10: 誤パス Read 3 件 + 正パス Read 3 件、4 秒間隔まで判明

→ **「assistant の主張 vs 実ファイル変更」を突合できるようになった**。これは Phase 2 (副作用ゼロの自動確認) の中核要件と同じものを Phase 1 で既に部分的に満たしている。

### 2. B (Bash) による「因果チェーン」の復元

v1 では「sqlite3 で GUID 取得した」程度だった所が、

- 07: `sqlite3 chat.db` → 現用 GUID 特定 → 実装 → `bash -n` syntax check 2 回 → 実機テスト → `iMessage;+;` で -1728 → `any;+;` に修正、というチェーンが見える
- 03: turn66-67 で `jj bookmark set main --allow-backwards` → `jj abandon` → `jj op restore` (ロールバックの操作経緯)
- 10: `ls -la <path>` の引数が判明 (v1 は「ls で確認」止まり)

→ **「なぜその結論になったか」の根拠** が assistant テキストの主張依存から、コマンドログ由来の事実に変わった。

### 3. S (Skill) / A (Agent) によるセッションの構造把握

v1 では完全に見えなかった:

- 03: turn20 で `itumono-nonstop` 発火 = SQLite 21 commit バーストの起点 (タイムスタンプで確認)
- 03: turn21 で `gh-monitor:watch-workflow` 起動 = push 後の CI 監視パターン
- 03: turn3 で Opus サブエージェント呼び出し (agmsg 比較の本体)
- 07: AskUserQuestion 4 回が Q タイプで分離 → ユーザーに委ねた判断ポイントが特定

→ **「このセッションを何が駆動したか」「どこで人間に委ねたか」** が構造として見える。Phase 1 の「未着地決定」抽出にはこの構造情報が直結する。

### 4. I (Info) による Monitor / compact イベントの可視化

- 03: turn67 の auto-compact (01:35) と turn68 の手動 `/compact` (10:33) → 文脈の境目が分かる (= 索引の「最終言及」精度に直結)
- 07: Monitor 3 件で launchd 起動の非同期検知パターン

→ **セッションの時間構造** (中断 / compact / 監視) が見える。長尺セッションの索引化で特に効く。

### 5. ターン範囲指定とタイムスタンプ

v1 は `sed -n 'N,Mp'` で近似していたのを、`timeline N..M` / `--last-turn N` / `--timestamps` で正確に絞れる。同日複数セッション問題 (v1 SUMMARY の指摘) は **turn 番号と UTC 時刻** を「最終言及」に併記すれば日付粒度問題が大幅に緩和される。

## 副作用: v1 の誤情報が訂正された

- 10-v2: v1 で「StructuredOutput `findings: []`」と書いていたが、CSA `--md=source` で実 Response を見ると **プレーンテキストの 2 段階 Response (`No security findings.`)** だった。v1 は `sdk-py` SDK の出力推測を事実として混入させていた疑い。
- 03-v2: v1 で「DR-0016 implemented (実装ファイル存在 + DR 番号コメント)」だったのを、v2 では「turn20 で db.ts/session-status.ts/subscriber-state.ts/message-queue.ts が file-ops で Write」と **より確かな証跡** に置き換え。

→ **TRU だけの索引は推測を事実として混ぜがち**。CSA で見ると引き締まる。

## v1 で挙げた 8 つの定義の穴に対する v2 の影響

| v1 の穴 | v2 で変化 |
|--------|---|
| 1. 相 3 値が状態空間不足 | **変化なし**。CSA は「相」の定義は補わない。`verified` / `closed` の追加は依然必要 |
| 2. 粒度ガイドライン不在 | **緩和**。file-ops と S/A イベントが「自然な区切り」を提供 (= スキル境界、サブエージェント境界、commit 境界) |
| 3. 事実 vs 推定の判定コスト | **大幅緩和**。file-ops で実 Write/Edit を直接確認できるので「assistant 主張依存」から脱却。Phase 2 の必要性が下がる方向 |
| 4. 最終言及が ISO 日付では不足 | **緩和**。turn 番号 + UTC 時刻が CSA で簡単に取れる。`YYYY-MM-DD turnNN` を新しい既定値にできる |
| 5. 参照列の粒度未定 | **緩和**。CSA のイベント ID (例 `B11fcd02c`, `R66f41d28`) が事実上の messageid 相当として使える。Phase 3 (messageid) の暫定実装が CSA で既に可能 |
| 6. リポ/プロジェクト横断の記録先 | **未解決**。file-ops で「どのリポを触ったか」は分かるが、「どこに書くか」の決定規則は別途必要 |
| 7. 公開可否 / スコープ列なし | **未解決**。CSA とは無関係 |
| 8. archive 戦略未定 | **未解決**。CSA とは無関係 |

## 確定したこと

1. **Phase 1 の手順に「CSA 必須」を入れるべき**。TRU 単体 (jq 直読) は推測混入リスクと取りこぼしが大きい。コスト面でも CSA は ASCII 出力で軽量 (生 jsonl の数十倍コンパクト)
2. **「参照」列の暫定既定値は CSA イベント ID** (例 `R66f41d28`)。messageid 採用 (Phase 3) を待たずに pinpoint 参照が可能
3. **「最終言及」の暫定既定値は `YYYY-MM-DD turnNN`**。日付のみは不可、時刻 (分まで) より turn 番号の方が grep 性が高い
4. **「実装した = file-ops に Write/Edit が出ている」を確信「事実」の必要条件にする**。assistant テキストだけは「事実」と書かない (= v2-03 で DR-0013 の事実化に成功した運用例)

## まだ決まらないこと

- 相の値の拡張 (verified / closed / aborted を入れるか、status 軸に分離するか) — **DR を 1 つ立てる必要あり**
- リポ横断の記録先決定木 — **Phase 1 の運用前提として未定義**
- 公開可否列 / スコープ列の有無 — **DR-0001 補遺 or 新 DR**
- archive 規約 — **2 週 active を試して測る、で OK**

## 次のアクション候補

- **DR-0002**: 相を 5 値 (spoken/recorded/implemented/verified/closed) に拡張、または相 × status の 2 軸分離。CSA で取れる証跡 (file-ops の有無) を verified 判定の根拠にする規約を含める
- **DR-0003**: Phase 1 手順を「CSA 必須 + 参照列 = CSA イベント ID + 最終言及 = `YYYY-MM-DD turnNN`」で正規化
- **同題材 (10 件) のうち残り 7 件も v2 で走らせる**: 件数差 (30〜40% 増) が他の中長セッションでも安定するか確認 (今は短中長 3 サンプル)
- **v1 / v2 の「迷った点」の差** を CSA 効果指標として記録 → 規約 v0.2 の効果測定の基準値にする

## 出力ファイル

- [agent-10-v2.md](./agent-10-v2.md) — nandakke prev `c366d86d` (短)
- [agent-07-v2.md](./agent-07-v2.md) — classroom-monitor `66b917d2` (中)
- [agent-03-v2.md](./agent-03-v2.md) — cmux-msg `46111dcc` (長)
- [../2026-06-18-phase1-trial-multi-agent/SUMMARY.md](../2026-06-18-phase1-trial-multi-agent/SUMMARY.md) — v1 (jq 版) の比較メモ
