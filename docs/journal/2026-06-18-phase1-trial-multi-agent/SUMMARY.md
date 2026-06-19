# Phase 1 素振り 10 並列の比較

10 セッションを別々のサブエージェント (Sonnet) に渡し、`DR-0001` / `ROADMAP` / `decisions-log` 試作見本だけを与えて、**やり方・スキーマ運用・出力フォーマットは完全に裁量** にして Phase 1 (記録層を手動で回す) を実行させた結果の比較。出力先パスだけ指定。

## 走らせた一覧

| # | 題材 | 抽出件数 | 主観の特徴 |
|---|------|--------|----------|
| 01 | session-analysis `61e8ab3e` | 8 | push 待ち → 相に表現できず next 列でカバー |
| 02 | rules-personal `f541f246` | 12 | 30h 長尺 + rebase conflict 中断、partial implemented 多発 |
| 03 | cmux-msg `46111dcc` | 15 | 最多。DR status と 相 の乖離 (Accepted ≠ implemented) を実機 grep で発見 |
| 04 | statusline `2d074463` | 13 | リポ横断変更 (rules-personal を修正) の記録先問題、時刻まで記録 |
| 05 | session-analysis `a168265e` | 9 | memory/ vs docs/ の記録場所、終端相 (closed) の不在 |
| 06 | classroom-monitor imessage `847a9fe0` | 6 | 3 分の reviewer クラッシュ未完了セッション、個人情報の公開可否列なし |
| 07 | classroom-monitor `66b917d2` | 8 | OS バージョン依存の確信表現、push 未実施を topic に上げる是非 |
| 08 | jj-worktree `7a73e0f4` | 5 | どのプロジェクトの索引か (jj-worktree vs cmux-msg)、ファイル書込み vs commit の境界 |
| 09 | hyoui `269559b3` | 16 | 大規模 (2.4MB)、regression を別 topic に立てる、未起票 issue を索引化 |
| 10 | nandakke `c366d86d` | 5 | 46 秒ワンショット security-review、決定が生まれないセッションの扱い |

抽出件数のばらつきが **5〜16** (= 3 倍以上)。題材ボリュームだけでなく **「何を topic として上げるか」の判断基準** が人 (エージェント) ごとに違うことが大きい。

## Phase 1 の定義で具体化されていない 8 つ

10 人全員またはほぼ全員が「ここで判断に迷った」と書いた共通の穴。これが **スタート地点として足りないもの**。

### 1. 相 (spoken / recorded / implemented) の 3 値が状態空間をカバーしていない

10 人中 **9 人が指摘**。具体的に表現できなかった状態:

- **push 待ち / commit 済だが main 未到達** (01, 02): partial implemented
- **DR Accepted だがコード未変更** (03): status と 相 の乖離
- **削除した・閉じた** (05): closed / done の終端相
- **議論のみで合意未確定** (04, 07): pending decision
- **試作的に動いた (Monitor task で動作確認)** (08): verified but not committed
- **テスト/レビュー結果 (findings = 0)** (10): verified
- **未起票 issue / 未完了タスク** (07, 09): tracked-but-not-recorded
- **未完了セッション (reviewer クラッシュ)** (06): aborted

→ **方向性**: 相は最低 5 値必要そう (`spoken / recorded / implemented / verified / closed`)。または「相」と「進捗 status」を直交軸にして 2 列に分ける案 (例: 相 = 議論段階、status = 着地状況)。

### 2. 粒度ガイドラインがない (= 索引数が 5〜16 で揺れる原因)

- 1 セッション 3 feature を 1 vs 3 エントリ (01)
- CI failure 2 回を 1 vs 2 エントリ (05)
- bug fix と regression を 1 vs 2 (09)
- `applescript_quote` 単体を上げるか「レビュー未完了」に包含するか (06)
- 46 秒セッションの記録下限 (10)

→ **方向性**: 「数日後にこれどうなってた? と聞きたくなる粒度」を判断基準に置く運用ヒューリスティクスを明文化。後から検索/合体する前提なら **粒度は細かめに倒す** のが安全 (= まとめ直しは可能、分割は再読み必要)。

### 3. 「事実 vs 推定」の判定コストがエージェント側に丸投げされている

- 「commit した」は事実、「main に到達」は推定 (02)
- DR/コードの突合 grep をどこまでやるか (03)
- OS バージョン依存の確信表現 (07)
- 「実機確認したが揮発リスクあり」中間状態 (08)

→ Phase 2 (副作用ゼロの自動確認) の要件が **既に Phase 1 段階で発生** している。Phase 1 で「確信」列を諦める (= 推定一律) か、最低限の確認手順を定型化するかの判断が要る。

### 4. 「最終言及」が ISO 日付だけでは足りない

- 同日に複数セッションがある (02, 04, 06) → 実際に rebase conflict が発生 (02)
- ロード時 (例: 「セッション冒頭/中盤/終盤」) で代替したい (03)
- 時刻 (分) まで入れた (04) vs 日付のみ (01)

→ **方向性**: 試作段階でも `ISO 日付 + セッション内位置 (前半/中盤/後半)` を最低条件にする。messageid 採用 (Phase 3) の根拠データが既に揃った。

### 5. 「参照」列の粒度がエージェント任せ

- セッション ID だけ書く (01, 05)
- コミット hash + ファイルパス + 行番号 (03, 09)
- DR 番号への内部リンク (02, 03)

→ **方向性**: 参照列は **複数粒度を 1 セルに同居** が現実的 (= 「sid + 主要 commit + 関連ファイル」を slash 区切り)。書式テンプレが必要。

### 6. リポ / プロジェクト横断の記録先が未定義

- claude-statusline セッションで rules-personal を修正 (04)
- jj-worktree セッションで cmux-msg に issue 起票 (08)
- cmux-msg セッションで hyoui に label issue 起票 (03)

→ **設計判断が必要**: nandakke の記録層は (a) プロジェクト単位 (b) セッション単位 (c) 横断 (中央集権) のどれか。DR-0001 は「複数プロジェクトのプロジェクト知識」と言っているが、書き先の決定規則は未定義。

### 7. 「決定にならない情報」を捨てるか拾うか

- 個人情報 (config に電話番号) (06): 公開可否列がない
- セッション挙動 (誤パス試行、reviewer クラッシュ) (06, 10): プロジェクト決定ではない
- memory への記録 (05): docs/ 以外のスコープ

→ **方向性**: スキーマに **「公開可否」「スコープ (project/session/memory)」列** を足すか、「索引は決定のみ・運用ログは別経路」と割り切るか。

### 8. 完了/archive 戦略が未定

- 完了エントリの next を「(完了)」と書くか、エントリ自体を archive するか (05)
- 完了が積み上がると索引が肥大化、「数日後の見やすさ」を損なう

→ **方向性**: Phase 1 試作で **2 週間で archive 行きの目安** を試す価値あり (= 短期は active、長期は別ファイル)。

## 副次的に見えたこと

### 全員が 6 列スキーマのテーブルを採用した

「フォーマット自由」と明示したのに 10/10 が見本踏襲。**試作見本がフォーマット選択を強く誘導** している。比較目的では多様性が損なわれた一方、Phase 1 の運用としては「同一フォーマットで揃う」のは長所 (= grep しやすい)。

### 全員が DR / ROADMAP / 見本を真面目に読んだ上で迷っている

つまり **読み込んでもなお不足する定義** が今回の 8 項目。読まないで雑にやった結果ではないので、文書を増補すれば改善する見込みが立つ。

### 「ai-title」「タイムスタンプ」「entrypoint」など jsonl メタの活用がばらばら

- ai-title を topic 抽出に使う (08) vs 無視 (01)
- entrypoint=sdk-py を補足 (10)
- セッション期間を分まで記録 (04)

→ jsonl から **自動抽出できるフィールド** (ai-title, 期間, entrypoint, modified files の集計) を Phase 1 の手順に組み込めば、初期 topic 候補をエージェントが見落としにくくなる。

## スタート地点として最低限決めるべきこと (= Phase 1 を「ふんわり」から脱却させるための最小規約)

優先順:

1. **相を 5 値に拡張**: `spoken / recorded / implemented / verified / closed`。同時に「相 = 確定段階」「status = 着地状況 (e.g. push-pending, main-merged, aborted)」の **2 軸を分離** するか、後者を next 列に押し込めるかを決める。
2. **記録先の決定規則**: (a) どのプロジェクトの索引に書くか (b) リポ横断変更をどう扱うか — の決定木を作る。
3. **粒度ガイドライン**: 「1 topic = 1 検索可能な質問」を原則に、CI failure・regression・push 待ちなどの典型ケースで「分ける/まとめる」の例を 3〜5 件 decisions-log に追記。
4. **「最終言及」を `YYYY-MM-DD/<position>`** (前半 / 中盤 / 後半) で記録。messageid 採用までの暫定。
5. **「参照」列のテンプレ**: `sid:<short> + commit:<sha7> + path:<rel>` を slash 区切りで併記。
6. **記録対象のスコープ列を追加**: `project / session / memory / cross-repo` のいずれか。公開可否はこのスコープから派生させる。
7. **archive 規約**: 完了エントリは 2 週間 active、それ以降は別ファイル (`decisions-log-archive-YYYY-MM.md`) に移す試行。

## 次のアクション候補

- 上の 1〜7 を反映した **Phase 1 規約 v0.2** を `docs/knowledge/2026-06-18-phase1-protocol-v0.2.md` として書き出す
- 同じ 10 セッションで **規約 v0.2 を適用したリトライ** を 3〜5 件だけ走らせ、抽出件数のばらつき・迷い点の減少を測る
- nandakke の DR-0001 §YAGNI に「Phase 1 規約は 1 回目の素振り後に v0.2 化する」を明記 (= 設計の二段構えを正規化)

## エージェントごとの出力ファイル

- [agent-01.md](./agent-01.md) — session-analysis `61e8ab3e`
- [agent-02.md](./agent-02.md) — rules-personal `f541f246`
- [agent-03.md](./agent-03.md) — cmux-msg `46111dcc`
- [agent-04.md](./agent-04.md) — statusline `2d074463`
- [agent-05.md](./agent-05.md) — session-analysis `a168265e`
- [agent-06.md](./agent-06.md) — classroom-monitor imessage `847a9fe0`
- [agent-07.md](./agent-07.md) — classroom-monitor `66b917d2`
- [agent-08.md](./agent-08.md) — jj-worktree `7a73e0f4`
- [agent-09.md](./agent-09.md) — hyoui `269559b3`
- [agent-10.md](./agent-10.md) — nandakke prev `c366d86d`
