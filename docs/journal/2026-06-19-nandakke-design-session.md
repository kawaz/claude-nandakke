# nandakke 設計検討セッション (2026-06-19)

## このファイルの位置付け

このセッション (Claude Code 連続会話、2026-06-18 開始 → 2026-06-19 継続) で
nandakke の設計が大きく動いた。**kawaz がこのセッションの存在を忘れる前に**
要点・未決・次アクションを記録する救命索引。

詳細議論の現物は session の jsonl (`88abf7b1-17e6-4ade-a166-361876270cd1.jsonl`)、
codex 向け全量ブリーフィングは `2026-06-19-design-brief-for-codex.md`。
このファイルは **kawaz が思い出すための地図**。

## セッションの発端

kawaz から「nandakke の Phase 1 はふんわりしすぎ。10 セッションで実際に試して
みて、やり方ごとサブエージェントに任せて足りないものを炙り出そう」という指示。
その後 3 段階の素振りを経て設計議論に発展した。

## 実験フェーズ (Phase 1 素振り)

3 段階で素振り、それぞれの SUMMARY が読書素材:

| 段階 | やったこと | SUMMARY |
|---|---|---|
| v1 (10 並列) | jq 直読、やり方も自由 | `docs/journal/2026-06-18-phase1-trial-multi-agent/SUMMARY.md` |
| v2 (3 件再走) | CSA 必須化 | `docs/journal/2026-06-18-phase1-trial-v2-csa/SUMMARY-v2.md` |
| v3 (60 並列) | -t 軸 × --md 軸の全パターン | `docs/journal/2026-06-18-phase1-trial-v3-matrix/SUMMARY-v3.md` |

### 実験で確定したこと

- **CSA 規約**: `-t TR --width 9999 --md=source` + `file-ops -d 1` が件数最多
- **md=source の効果は非対称**: R 型で +10.7%、T 型で +1.7%
- **TRU 単体は推測混入リスク**: v1 で「StructuredOutput findings:[]」と書いた
  箇所が実はプレーンテキスト Response (= TRU 抽出は SDK 出力推測を事実扱いする)
- **file-ops で「assistant 主張依存」→「観測裏取り」に格上げ可能**: DR-0013 で
  「Accepted だが package.json Write なし」のような **否定証跡** も取れた

### 実験で反省したこと (重要)

**v3 まで「件数」を主指標にした最適化が、そもそも前提が間違いだった**。kawaz の
指摘で:

- 件数 ≠ 索引の有用性 (v1 SUMMARY で既に気付くべきだった)
- 本来の評価軸は「人間/AI が後で見て当たりを付けられたか」
- 件数指標は代理に過ぎない

→ 評価実験は **Q&A 正答率 + chain/cross/cycle 再構成テスト** に切り替える方針。

## 並行プロジェクト: claude-local-issue の登場

実験のレビューに合わせて kawaz が `claude-local-issue` プラグインを設計・実装
(zip 同梱で受領、これから cc に持ち込む)。これが nandakke の議論に直接影響した。

local-issue から学んだ原則:

- **status と category の 2 軸分離**: 「変える主体が違う」で分離
- **status 7 値**: rules 側 5 値 (削除運用前提) を拡張
- **`close_reason` を `string[]`** で正規化 (`["dr/DR-0007", "implemented"]`)
- **時系列メタは全フィールド full ISO8601 + TZ、mtime 不使用**
- **archive は「見えなくする」目的** で削除と同じ効果、ファイルは残るが index
  から外す
- **「混ぜるな」警告**: archive は索引源にしない。思想が逆 (索引は参照されてこそ
  価値、archive は見せない目的)

## 主な議論分岐点と確定事項

### (1) 評価指標の切替 (= v3 から v4 への大転換)

旧: 件数最多が良い → 新: Q&A 正答率 + 3 種の再構成テスト

3 種の grand truth セット (kawaz が具体例を提供):

| grand truth | 内容 | テスト |
|---|---|---|
| **chain** | 連絡帳→classroom-monitor の 7 topic 連鎖 | 起点から完了まで辿れるか |
| **cross** | cache-warden A3 (open) ↔ classroom-monitor B7 (shipped) の交差 | 未解決 A3 に対する解候補 B7 を suggestion できるか |
| **cycle** | nandakke ↔ 60 本テスト ↔ local-issue ↔ nandakke の自己言及 | ドッグフーディングループを再構成できるか |

### (2) 永続化形式

| 案 | 判定 |
|---|---|
| A (純ファイル Markdown) | 却下 (kawaz) |
| B (TSV/CSV) | 却下 (kawaz) |
| C (SQLite 正規化) | **本命** (cmux-msg DR-0016 流用宣言と整合) |
| D (JSONL append) | 微妙、経緯は journal/DR/issue で足りる |
| E (Markdown + SQLite ハイブリッド) | 却下、2 重管理 |
| F (DuckDB on Parquet) | **別軸候補** (動かないナレッジ DB / 統計解析の将来軸) |
| G (Neo4j 等 graph DB) | 初回「やりすぎ」評価 → **再評価へ** |

#### G の再評価 (Claude 自省)

議論を進めるうちに要件 (chain / cross / cycle / link kind 拡張 / 「全部繋がる」前提) が
明確化し、これは **graph DB の本流ユースケース** と判明。

**Kùzu** (embedded graph DB, https://kuzudb.com/) を発見:
- 組み込み (SQLite と同じ感覚、単一ファイル DB)
- Cypher subset サポート
- Parquet 統合 (F 軸 DuckDB との相性)
- kawaz の予防線 (「やりすぎ」「詳しくない」) を緩和

舵を切るか否かは **codex に独立レビュー依頼中**。

### (3) スキーマ素案 (確定したもの・議論中のもの)

```sql
topics (
  id INTEGER PK,
  sid TEXT NULL,                -- セッション外 topic を許容
  repo TEXT NULL,               -- プロジェクト外 topic を許容
  domain TEXT NOT NULL,         -- dev/life/creative/meta/misc
  summary TEXT NOT NULL,        -- 1 行 (chain 出力用)
  body TEXT NULL,
  stage TEXT NOT NULL,          -- 議論軸 (再設計対象、3 案残り)
  landing TEXT,                 -- 着地軸 (再設計対象)
  created_at, updated_at, last_mention_at
)

evidence (
  id INTEGER PK,
  topic_id FK,
  kind TEXT NOT NULL,           -- 'csa' | 'file-ops' | 'vcs' | 'dr' | 'local-issue' | 'observation' | ...
  ref TEXT NOT NULL,            -- jj/git は ref 形式で自動判別 (jj=z+15char, git=hex)
  sid TEXT NULL,                -- 外部参照時のみ
  repo TEXT NULL,
  inserted_at
)

topic_links (
  src_topic_id FK,
  kind TEXT NOT NULL,           -- 下記語彙
  dst_ref TEXT NOT NULL,        -- 'topic/<id>' or 'local-issue/<repo>/<slug>' or 'dr/...'
  inserted_at
)
```

### (4) topic_links.kind の語彙 (議論で出てきた集合)

| グループ | kind 群 |
|---|---|
| 単一連鎖系 | spawned_from / triggered_by / solves / verifies / closes / contains / result_of |
| 階層・推移系 | supersedes / depends / related / converged_to |
| cross-link 系 | solves_via / repurposed_for / applies_to / source / analogous_to |
| ドッグフーディング系 | spawned_during / fed_back_to / surfaced_problem / delivered |

最小セットを実装し、必要時に追加する方針。AI の判定負荷とのバランス未確定。

### (5) ドメインカテゴリ (今回の追加)

「チャット迷子記録」の前提で、プロジェクト外 topic も大量に発生する。

- `dev` / `life` / `creative` / `meta` / `misc` の 5 値
- 1 topic に 1 つ (1:多にしない、迷ったら misc に倒して後で分割可能)
- 評価指標として「収束率」「迷子救出率」も追加

### (6) VCS 統一

`kind='vcs'` で git/jj を統合、ref 形式で自動判別:
- jj change-id: `z` + 15 文字 = 16 文字
- git commit-id: 16 進数のみ

将来 hg を増やしても kind は `vcs` のまま、ref 形式判別を増やすだけ。

### (7) nandakke と local-issue の責務分離

| 対象 | 持つ場所 |
|---|---|
| topic 状態 (相 / landing / 確信 / 最終言及) | nandakke |
| 証跡網 | nandakke |
| topic 間関係 | nandakke |
| アクション項目進行 | local-issue |
| 議論経緯 | journal |
| 設計判断確定 | DR |
| 統計解析 | F (将来) |

nandakke.evidence.ref から `local-issue/<repo>/<slug>` を参照する形で連携。

## 未確定事項 (codex レビュー依頼中)

問 1: 永続化形式 (SQLite vs Kùzu、段階移行 vs 最初から graph)
問 2: 相スキーマ (1 軸拡張 / 2 軸割り / 1 軸 + フラグ の 3 案)
問 3: 評価実験プロトコル
問 4: nandakke と local-issue の責務分離の妥当性
問 5: Phase 5 (可視化) の優先度
問 6: 見落としている観点

詳細は `2026-06-19-design-brief-for-codex.md` 参照。

## codex 並行レビューの受領 (2026-06-19 完了)

codex に独立レビューを依頼 (brief: `2026-06-19-design-brief-for-codex.md`)。Claude の議論が **複雑化バイアスに引っ張られていた** 可能性を構造的に補正してくれた。

### codex の主要な刺さりどころ

- **「LLM は構造を作ること自体を価値と錯覚する」**: graph DB 再評価、link kind 10+ 種類、cycle 検出と Claude が複雑化方向に積み上げていた。DR-0001 原点 (「全部読まずに当たりを付ける」) からの逸脱リスク
- **Phase 1 は SQLite 確定 + graph-shaped スキーマ**: 「索引思想が悪い」と「DB が重かった」の **失敗分離** のため Kùzu 同時検証は避ける
- **3 軸スキーマ (stage / landing / confidence)**: confidence を独立列で持つ
- **link kind は 6 個から始める**: `causes / depends / solves / contains / supersedes / related`、必要時に分化
- **質問セット (20 問) DR が DB 選定 DR より先**: 「DB を選んだ後に質問を作ると、その DB に有利な評価になる」
- **inter-rater reliability の指標** (= 別 Claude が同じ link を付けるか)
- **blind な過去セッションを評価に混ぜる** (= 評価者汚染回避)

### codex が指摘した 11 個の盲点 (= Claude の見落とし)

1. 構造作り自体の価値錯覚
2. 入力品質の問題 (構造化しても「精密な嘘」)
3. link kind の判定負荷 (意味重複)
4. 過リンク化の危険 (巨大連想網)
5. **負の情報の一級扱い** (「なかった」「不能」)
6. **temporal validity** (いつ時点の真実か)
7. 運用摩擦 (書かれなくなるリスク)
8. **評価者汚染** (自己言及構造)
9. 古い正解の危険 (環境変化)
10. **削除/archive/忘却の設計** (nandakke 側にも要る)
11. **セキュリティ/プライバシー境界** (life/dev/meta 跨ぎ)

詳細は session jsonl 内の codex 応答 (turn 末尾近辺) 参照。

## メタ発見: 「広げる→絞る」役割分担

このセッションでのプロセスとして:
- **Claude (= 広げる役)**: 要素拾い、選択肢列挙、可能性の網羅、kawaz の例から構造抽出
- **codex (= 絞る役)**: 現実着地、複雑化バイアスの補正、最小構成への絞り込み

両者を kawaz が **手元で別役割として走らせる** ことで議論が機能した。将来 nandakke 上で「広げる用エージェント」と「絞る用エージェント」を別 prompt で常備する運用も検討候補 (= 1 つの AI に両方やらせると複雑化バイアスや絞りすぎが起きやすい)。

## 次のアクション (確定版、codex 反映後)

### Phase 1 試作 (= 実装と実験フェーズ) の最小スコープ

1. **質問セット (20 問) を確定する**
   - chain / cross / cycle の grand truth から派生する問
   - kawaz が知らない過去セッション (blind 素材) からの問も混ぜる (評価者汚染回避)
   - 質問源自体の設計が新たな小実験
2. **SQLite で graph-shaped スキーマ v0 を切る**
   - 3 軸 (stage / landing / confidence)
   - link kind 6 個 (causes / depends / solves / contains / supersedes / related)
   - topics / evidence / topic_links の 3 表
3. **このセッション自体を grand truth 例 3 (cycle) として SQLite に手書き登録する**
   - 自己 dogfood、忘れる前に
   - 連絡帳→classroom-monitor (chain 例 1) と cache-warden ↔ classroom-monitor (cross 例 2) も同様
4. **20 問を SQLite と「索引なし (jsonl 直渡し)」の両方に対して別 Claude セッションで回答させ、正答率を測る**
   - これが「Phase 1 が valid か」の第一段検証

### 順序の論拠

- **質問セット先行** (codex 提案): DB に有利な評価を避ける
- **SQLite で確定** (codex 提案): graph DB 検証は失敗時に切り分け不能
- **grand truth は kawaz の頭の中の実例**: 連絡帳/cache-warden/local-issue 系の経緯は kawaz の生の素材

### 後続 DR (= 質問セット運用で要件が固まったら起こす)

- DR-0002: 質問セット (= 評価の grand truth、20 問)
- DR-0003: 評価実験プロトコル (= 指標群、inter-rater reliability 含む)
- DR-0004: Phase 1 試作スキーマ (= 3 軸 + 6 link kind + SQLite)
- DR-0005: CSA 規約 (= v3 の `-t TR --md=source --width 9999 + file-ops`、件数指標が valid な前提でしか言えない但し書きつき)
- DR-0006: local-issue 連携の構造原則 (= slug 安定性、observed_status キャッシュ規約)

### 棚上げ (= 後で必要時に検討)

- Kùzu (embedded graph DB) への移行検討: Phase 1 で SQLite が辛いと判明したら
- link kind の分化: 6 個で運用してみて足りないと判明したら
- 可視化: Phase 2-3 で minimal graph (Mermaid/DOT)、Phase 5 でリッチ可視化
- F (DuckDB on Parquet) 別レイヤ
- 削除/archive/忘却の設計
- temporal validity の表現
- プライバシー境界

## セッション終了 (2026-06-19)

ここで一旦区切り、実装と実験の繰り返しフェーズに入る。次セッションでは:

1. このファイル (journal) を Read 1 回で全体把握できる
2. 「次のアクション (確定版)」セクションから着手可能
3. 質問セット 20 問の素材は journal 全体 (= kawaz の例、grand truth 3 つ、議論経緯)

実装/実験の進捗を別 journal に残しつつ、必要時に DR を起こす。

## kawaz の指摘・洞察ハイライト

## kawaz の指摘・洞察ハイライト

- 「いきなりLLMがStructuredOutputとか言い出したら疑え」(v2 で実例検証)
- 「件数 ≠ 索引の有用性」(評価指標を根本的に切り替える契機)
- 「これは混ぜるな」(local-issue archive と nandakke 索引、思想が逆)
- 「nandakke は issue より DB 構造が複雑」(ファイル前提を捨てる契機)
- 「だいたい色んなものが繋がってる」(graph DB 再評価の契機)
- 「ドッグフーディングが多い」(cycle 検出を本質要件とした契機)

これらは私 (Claude) の前提を **段階的に裏返した**。kawaz の指摘なしには
私は「ファイル + 件数」の素朴モデルで結論していた可能性が高い。

## このセッションの構造的位置付け

このセッション自体が **nandakke の grand truth 例 3 (cycle)** の構成要素:

```
nandakke 構想 → 60 本テスト → 完了判定問題 surfaced → local-issue spawned
  → local-issue delivered → fed_back_to nandakke → 設計再検討 (このセッション)
  → 次の DR 群へ
```

つまり **このセッションで作る nandakke は、このセッション自体を題材として
追跡できる必要がある**。第一段の検証材料が自分自身の構築過程になる。

## 関連ファイル

- ブリーフィング (codex 向け全量): `2026-06-19-design-brief-for-codex.md`
- v1/v2/v3 実験 SUMMARY: 上記の通り 3 ファイル
- local-issue 現物 (zip 展開済): `/Users/kawaz/.claude-personal/jobs/88abf7b1/tmp/claude-local-issue/`
- nandakke DR-0001: `docs/decisions/DR-0001-knowledge-index-sidecar-architecture.md`
- nandakke ROADMAP: `docs/ROADMAP.md`
- セッション jsonl 本体: `~/.claude-personal/projects/-Users-kawaz--local-share-repos-github-com-kawaz-claude-nandakke-main/88abf7b1-17e6-4ade-a166-361876270cd1.jsonl`
