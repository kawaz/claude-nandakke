# nandakke 設計検討ブリーフィング (codex 向け)

作成: 2026-06-19
作成者: Claude (現セッション)
宛先: codex (独立レビュー依頼)

## このドキュメントの目的

kawaz の指示で codex に independent review を依頼するためのブリーフィング。
nandakke プロジェクトの現在の設計検討を漏らさず伝え、特に **永続化形式の選択
(SQLite vs embedded graph DB Kùzu)** について codex の独立意見を求める。

結論は決めつけずに材料を提示する。Claude (私) の判断バイアスを排除し、second
opinion として独立に評価してほしい。

## 1. nandakke とは

「AI に『ぼんやりした正確な全体インデックス』を持たせる」ための Claude Code
プラグイン (実装前、設計検討中)。発端は「kawaz のチャット会話迷子を解決したい」。

人間が無意識に持っているプロジェクトの全体把握 (= 正確じゃないが、どこに何が
あるか当たりが付く) を、AI 用の外部索引として与える。「全部読む (重い) か
読まない (雑) か」の二択を、「ぼんやり全体を把握 → 必要なら正確に取りに行く」
に置き換える。

詳細は以下を読むこと:

- `/Users/kawaz/.local/share/repos/github.com/kawaz/claude-nandakke/main/docs/decisions/DR-0001-knowledge-index-sidecar-architecture.md`
- `/Users/kawaz/.local/share/repos/github.com/kawaz/claude-nandakke/main/docs/ROADMAP.md`
- `/Users/kawaz/.local/share/repos/github.com/kawaz/claude-nandakke/main/docs/knowledge/2026-06-17-decisions-log.md` (試作見本)

## 2. これまでの実験経過

### v1 (10 並列、jq 直読)

10 セッションを別々のサブエージェントに渡し、Phase 1 (索引手動運用) を試行。
やり方も自由にさせて解釈差を比較。結果は `docs/journal/2026-06-18-phase1-trial-multi-agent/SUMMARY.md`。

主な発見:
- 抽出件数 5〜16 件で 3 倍のばらつき → 「規模差より topic 判断基準の緩さ」
- 8 つの「定義の穴」が浮上 (相 3 値不足 / 粒度ガイド不在 / 事実推定判定コスト
  等)。詳細は当該 SUMMARY 参照

### v2 (3 件、CSA 必須)

claude-session-analysis (CSA) ツールを必須にして 3 件再走。詳細は
`docs/journal/2026-06-18-phase1-trial-v2-csa/SUMMARY-v2.md`。

主な発見:
- TRU (assistant/user テキスト) だけだと推測混入リスクがある (v1 agent が
  "StructuredOutput findings:[]" と書いた箇所が実はプレーンテキスト Response
  だった)
- file-ops で実 Write/Edit を確認することで「assistant 主張依存」から
  「観測裏取り」に格上げできる
- DR-0013 の「Accepted だが package.json Write なし」のような **否定証跡**
  も取れる

### v3 (60 並列、6 条件 × 10 セッション マトリクス)

CSA の使い方 (md ありなし、T/R/TR の組合せ) を全パターン試して比較。詳細は
`docs/journal/2026-06-18-phase1-trial-v3-matrix/SUMMARY-v3.md`。

主な発見:
- 条件 F (`-t TR --width 9999 --md=source` + `file-ops -d 1`) が件数最多 (121
  件)、9/10 セッションで最高
- md=source の効果は R 型で +10.7%、T 型で +1.7% という非対称
- 巨大セッション (cmux-msg 6.9MB) で F-03 が "Prompt is too long" failure
  だがファイルは完了 (= 通知時のエラー)

**重要な反省**: v3 まで「件数」を主指標にして最適化したが、kawaz の指摘で
**件数 ≠ 索引の有用性** と判明 (v1 でも既に観測されていた)。本来の評価軸は
「人間/AI が後で見て当たりを付けられたか = 索引としての有用性」であって、件数
はその代理に過ぎない。次の評価実験は Q&A 正答率 / chain 再構成 / cross-link
検出 / cycle 検出 で測る予定。

## 3. パラメータでは消えない設計の穴

v3 で確定したのは CSA の叩き方だけ。スキーマ側の問題が残っている。

### (a) 相スキーマの 3 値が状態空間を覆えていない (16/60 で最多言及)

`spoken / recorded / implemented` のどれにも収まらない状態が頻発:

- push 待ち (commit 済だが未 push)
- DR Accepted だがコード未変更 (cmux-msg DR-0013 の例)
- 削除した
- 試作的に動作確認した
- 未完了 / 中断

### (b) 事実 vs 推定の区別 (11/60)

「assistant が言った」は事実か推定か判定困難。file-ops との突合で裏取りすれば
事実化できるが、スキーマ上どう表現するか未定。

### (c) 最終言及の粒度 (6/60)

ISO 日付では足りない (同日複数セッションで rebase conflict 発生例あり)。
`YYYY-MM-DD turnNN` 暫定解。

## 4. 並行して claude-local-issue を作った

設計検討中に「完了判定むずい」問題が surfaced し、別プラグイン
`claude-local-issue` を派生 → 設計完了 (近日運用開始)。これ自体が nandakke の
題材になる自己言及的構造。

local-issue の構造で重要な点 (詳細は下記読書):
- **status と category の 2 軸分離**: status = 状態 (idea/open/wip/blocked/
  pending-sublimation/discarded/resolved)、category = 分類 (idea/bug/request/
  design/task/tech-memo)。「変える主体が違う」で分離
- **status 7 値**: rules 側 5 値 (削除運用前提) を拡張
- **`close_reason` を `string[]`** で正規化 (`["dr/DR-0007", "implemented"]`)
- **時系列メタは全フィールド full ISO8601 + TZ、mtime 不使用**
- **archive は「見えなくする」目的** で削除と同じ効果、ファイルは残るが index
  からは外れる
- **archive を nandakke 索引源にしない**: 思想が逆 (= 索引は参照されてこそ価値、
  archive は見せない目的)

詳細を読むこと:

- `/Users/kawaz/.claude-personal/jobs/88abf7b1/tmp/claude-local-issue/docs/DESIGN-ja.md`
- `/Users/kawaz/.claude-personal/jobs/88abf7b1/tmp/claude-local-issue/docs/decisions/DR-0001-skill-over-hook-isolation.md`
- `/Users/kawaz/.claude-personal/jobs/88abf7b1/tmp/claude-local-issue/docs/decisions/DR-0002-db-model-supersedes-delete-flow.md`
- `/Users/kawaz/.claude-personal/jobs/88abf7b1/tmp/claude-local-issue/skills/write/SKILL.md`
- `/Users/kawaz/.claude-personal/jobs/88abf7b1/tmp/claude-local-issue/skills/write/templates/issue.md`

## 5. 議論で確定したこと (現在の素案)

ここまでの kawaz との対話で固まった素案:

### (a) 永続化形式

- A (純ファイル Markdown) / B (TSV/CSV) は kawaz 却下
- **C (SQLite 正規化) 本命** (cmux-msg DR-0016 流用宣言と整合)
- D (JSONL append) は微妙 (経緯は issue/journal/DR で足りる)
- E (Markdown + SQLite ハイブリッド) は 2 重管理で却下
- **F (DuckDB on Parquet) 別軸候補** (動かないナレッジ DB / 統計解析の将来軸)
- G (Neo4j) は当初「やりすぎ」と Claude 評価したが、後述の要件展開で **再評価必要**

### (b) 役割分担

| 対象 | 持つ場所 |
|---|---|
| topic 状態 (相 / landing / 確信 / 最終言及) | nandakke |
| 証跡網 | nandakke |
| topic 間関係 | nandakke |
| アクション項目進行 | local-issue |
| 議論経緯 | journal |
| 設計判断確定 | DR |
| 統計解析 | F (将来) |

### (c) スキーマ素案 (Claude が積み上げ中、未確定)

```sql
topics (
  id INTEGER PK,
  sid TEXT NULL,
  repo TEXT NULL,
  domain TEXT NOT NULL,       -- dev/life/creative/meta/misc
  summary TEXT NOT NULL,      -- 1 行 (chain 出力用)
  body TEXT NULL,
  stage TEXT NOT NULL,        -- 議論軸 (再設計対象)
  landing TEXT,               -- 着地軸 (再設計対象)
  created_at, updated_at, last_mention_at
)

evidence (
  id INTEGER PK,
  topic_id FK,
  kind TEXT,    -- 'csa' | 'file-ops' | 'vcs' | 'dr' | 'finding' | 'runbook' | 'journal' | 'local-issue' | 'observation'
  ref TEXT,     -- 'R66f41d28' | 'turn20' | 'abc1234' | 'z...' (jj) | 'DR-0013' | etc
  sid TEXT NULL,
  repo TEXT NULL,
  inserted_at
)

topic_links (
  src_topic_id FK,
  kind TEXT,    -- 下記 link kind 群
  dst_ref TEXT, -- 'topic/<id>' or 'local-issue/<repo>/<slug>' or 'dr/...' 等
  inserted_at
)
```

VCS は `kind='vcs'` 統一、jj/git は ref 形式で自動判別 (jj=`z`+15char、git=hex)。

`domain` は 1 topic に 1 つ。

### (d) topic_links.kind の語彙 (議論で出てきた集合)

- 単一連鎖系: `spawned_from / triggered_by / solves / verifies / closes / contains / result_of`
- 階層・推移系: `supersedes / depends / related / converged_to`
- cross-link 系: `solves_via / repurposed_for / applies_to / source / analogous_to`
- ドッグフーディング系: `spawned_during / fed_back_to / surfaced_problem / delivered`

これらが「最小セット」か「使いすぎ」か未確定。AI が判定する負荷も考慮要。

## 6. graph 構造が必要な 3 つの具体例

実際の kawaz の頭の中で起きていることを 3 例分析した。

### 例 1: 単一連鎖 (life→dev→life の物語)

```
1 連絡帳チェック (life ルーチン、数年前〜)
  ↓ triggered_by
2 高学年で classroom 投稿に変化 (life)
  ↓ spawned_from
3 classroom 投稿の自動通知が欲しい (life→dev 境界)
  ↓ spawned_from
4 classroom-monitor を作る (dev)
  ↓ contains
5 iMessage 通知実装 / launchd 設定 / chat_id 形式問題 (dev、複数子 topic)
  ↓ verifies
6 2026-06-18 e2e 動作確認 (帰宅前に通知届) (dev/life)
  ↓ closes
7 連絡帳チェックの自動化が機能している (life)
```

domain を跨ぐ 7 topic 連鎖。recursive CTE で再構成可能。

### 例 2: 2 連鎖の交差 (cross-domain insight)

```
連鎖 A (cache-warden):
  A1 リモート生体認証ゲートを作る (dev)
  A2 WebRTC + Passkey で実現 (dev, decided)
  A3 通知経路をどうするか? (dev, open のまま放置 30 日+)
  A4 スマホアプリ作る? (dev, stalled)

連鎖 B (classroom-monitor):
  B5 最初 say で PC 音声 (dev)
  B6 家族全員チャットで欲しい (life/dev 境界)
  B7 iMessage で送れる → 動作確認 OK (dev, shipped)

交差 X (気付き):
  X B7 の iMessage 通知パターンが A3 (cache-warden 通知問題) の解決手段に使える
    domain: meta
    stage: noted
    links:
      - solves_via, dst: topic/B7  (A3 を B7 で解く)
      - source, dst: topic/B7      (B7 を源として)
```

未解決 (A3) と既存解 (B7) を結ぶ気付き X が **独立 topic** として残る。
nandakke が「過去の解決資産を未解決問題に suggestion」できるかのテスト。

### 例 3: 自己言及 cycle (ドッグフーディング)

```
nandakke 構想 (チャット迷子解決)
  ↓ spawned_during
60 本テスト実施
  ↓ surfaced_problem
完了判定むずい問題
  ↓ spawned_from
local-issue 構想
  ↓ delivered
local-issue 完成
  ↓ fed_back_to ★ cycle 完結
nandakke を local-issue 前提に書き直す
  ↓ resumes
nandakke 構想 (= cycle の始点に戻る)
```

DAG でなく cycle を含む graph。recursive CTE では visited set + depth limit
が必要。

### kawaz の言明

> だいたい色んなものが繋がってることが多い。特に開発だけでもドッグフーディング
> が多いので

これは **「全部繋がっている」前提**。isolated topic は例外で、ほぼ全 topic が
何かと link する想定。link がない topic は AI に「これ何かと関係ないですか?」
と問わせる contigent。

## 7. graph DB に舵を切るべきか? (= レビュー依頼の本題)

Claude (私) は当初 G (Neo4j) を「やりすぎ」と評価し却下した。これは:

- kawaz が「詳しくない」と予防線を張った
- cmux-msg DR-0016 流用宣言 (SQLite hybrid) との整合を優先した

しかし後続の議論で出てきた要件:

- chain 再構成 / cross-link 検出 / cycle 検出 / N-hop 近傍
- link kind がどんどん増える (10+ 種類)
- 「全部繋がっている」が前提
- 孤立 topic 探索
- 可視化 (ROADMAP Phase 5)

これは **graph DB の本流ユースケース** に見える。

### Claude が再評価した選択肢

| 選択肢 | 評価 |
|---|---|
| SQLite + recursive CTE で graph を擬似 | 可能だが visited / depth boilerplate / N-hop が複雑 / graph アルゴリズム自前 |
| **Kùzu (embedded graph DB)** | **本命候補**。SQLite と同じ単一ファイル DB、Cypher subset、Parquet 統合 (F 軸との相性) |
| Neo4j Community | server 型で重い、kawaz の使い慣れない領域 |
| Memgraph | in-memory server 型、heavy |
| Apache AGE | PostgreSQL extension、PG 前提が新規 |

Kùzu (https://kuzudb.com/) は kawaz の予防線 (「やりすぎ」「詳しくない」) を
緩和する選択肢として浮上。embedded で SQLite と同感覚、Cypher subset、Parquet
連携 (F の DuckDB 軸とも親和性高い)。

### 段階導入の現実解

- **Phase 1 試作**: SQLite で素早く回す (= 評価実験のため)
- **評価実験 (chain / cross / cycle 3 つの grand truth テスト)** で要件が固まる
- 要件確定後、SQLite で書きにくいと判明したら Kùzu に lossless 移行
- もしくは **最初から Kùzu**: 試作の段階で graph 操作の素直さを体感する

どちらが筋かは未確定。

## 8. codex への問い (このブリーフィングの目的)

以下を独立に評価してほしい。Claude (私) の見解に引っ張られず、別の観点で意見
を出してほしい:

### 問 1: 永続化形式

- nandakke の要件 (chain / cross / cycle / link kind 拡張 / 全部繋がる前提) に
  対して、SQLite (recursive CTE) と embedded graph DB (Kùzu 等) のどちらが筋か?
- Kùzu 以外で考慮すべき embedded graph DB / graph 拡張は?
- Phase 1 試作は SQLite で始めて後で移行 vs 最初から graph DB のどちらが安全か?

### 問 2: 相スキーマ

- 現在 1 軸 (spoken/recorded/implemented) が状態空間を覆えていない問題に対し:
  - 案 A: 1 軸を 5-7 値に拡張 (local-issue の 7 値踏襲)
  - 案 B: 2 軸 (議論フェーズ × 着地状況) に割る
  - 案 C: 1 軸 + 直交フラグ (discarded / aborted)
- どれが筋か。それとも別の構造があるか?

### 問 3: 評価実験

- 件数指標を捨て、Q&A 正答率 + chain/cross/cycle 再構成テストで評価する方針は
  妥当か?
- 他に測るべき指標はあるか?
- grand truth (例 1/2/3) を kawaz が手動で SQLite/Kùzu に流し込む方法で第一段
  検証を始める案は適切か?

### 問 4: nandakke と local-issue の責務分離

- topic 状態 (nandakke) と アクション項目進行 (local-issue) を分離する方針は
  妥当か? 2 重管理にならないか?
- evidence.ref から local-issue/<repo>/<slug> を指す形式は適切か?

### 問 5: ROADMAP Phase 5 (可視化) の優先度

- cycle / cross / chain を全部含む graph の可視化は Phase 5 でよいか、もっと
  早期 (Phase 2-3) に置くべきか?
- D3 force-directed / Mermaid / Cytoscape / Kùzu Explorer のどれが筋か?

### 問 6: 見落としている観点

- ここまでの議論で漏れている本質的な観点があるか?
- Claude が見落としやすい盲点はどこか?

## 9. 自由形式の意見も歓迎

上記の問に縛らず、設計全体に対して気になる点・代案・別の発想があれば自由に
書いて欲しい。kawaz は「結論を急がせない」「材料を広く出させる」スタンスなので、
不確実性を表明してよい (= 「これは判断保留が筋」も valid な答え)。

---

返答は kawaz と Claude が読む。明示的な指示や決定はせず、観点と論拠を提示
する形でよい。

宜しくお願いします。
