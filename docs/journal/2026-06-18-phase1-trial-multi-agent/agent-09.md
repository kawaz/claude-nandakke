# Phase 1 試行 — agent-09 の記録

題材セッション: `269559b3-fb71-4a89-bae6-95940a4aa65e`
プロジェクト: `kawaz/hyoui`
セッション日時: 2026-06-16 〜 2026-06-17 (UTC)

---

## 索引

| topic | 相 | 確信 | 最終言及 | 参照 | next |
|---|---|---|---|---|---|
| `hyoui input "text:..." "key:Enter"` 1 invocation で Enter が落ちる bug | implemented | 事実 | 2026-06-17 | `docs/issue/2026-06-16-bug-input-text-key-enter-not-sent.md` (削除済、journal 昇華) / `docs/journal/2026-06-16-pty-drain-ack-implementation.md` | 完了 (DR-0021 + v0.7.0) |
| root cause: `text:` 完了 = socket flush、PTY drain は非同期 (race) | recorded | 事実 | 2026-06-16 | `crates/hyoui-cli/src/main.rs:3161-3174`, `input_handlers.rs:66`, `control.rs:173-175` | DR-0021 で修正済 |
| 修正方針: PTY drain ack (`TYPE_RAW_ACK = 0x02`) 採用 | implemented | 事実 | 2026-06-17 | DR-0021 / v0.7.0 | 完了 |
| regression: python -i + 1038 B 超で `frame decode failed while waiting raw_ack` | implemented | 事実 | 2026-06-17 | `attach.rs:1011` (`recv_raw_ack_inner`) | v0.7.0 内で修正済 (poll(2) 方式に切替) |
| regression root cause: `set_read_timeout` + `read_exact` の部分読み破棄 + partial bytes を size として誤認 | recorded | 事実 | 2026-06-17 | `attach.rs:1011` 周辺 | DR-0021 に記録済 |
| `screen snapshot --format=json` 未配線 (flag のみ受理、daemon CBOR を変換せず) | implemented | 事実 | 2026-06-17 | `crates/hyoui-cli/src/main.rs:2919`, `3002` / v0.7.1 | 完了 (CLI 段で serde_json 変換) |
| snapshot help/README に「未配線、jq 前に CBOR decode 必要」と逆説明が残存 | implemented | 事実 | 2026-06-17 | `cli.rs:4170`, `README-ja.md §6` / v0.7.2 | 完了 |
| `hyoui input --help` NOTE が「未実装で exit 1」と書いていたが実際は全 spec 配線済 | implemented | 事実 | 2026-06-17 | `cli.rs:9,892-895,4592` / v0.7.3 | 完了 |
| `hyoui input` の並列 race 問題: 複数 client が同一 PTY に割り込み可能 | implemented | 事実 | 2026-06-17 | DR-0022 / v0.8.0 | 完了 (invocation 全体 auto-lock) |
| auto-lock 設計: wait 中 lock 保持 vs 解放の議論 | recorded | 事実 | 2026-06-17 | codex adversarial review + Workflow 4-plan / DR-0022 | 保持を採用 (案 B)。DR-0022 に記録 |
| DR-0006 §7/§8.5 改定: release 仕様 + auto-lock policy | recorded | 事実 | 2026-06-17 | DR-0006 / DR-0021 §4 / DR-0022 | 完了 |
| cmux-msg v0.29.0 → v0.30.2: subscribe が daemon 非依存に | implemented | 事実 | 2026-06-17 | cmux-msg plugin update / `${CLAUDE_PLUGIN_ROOT}/bin/cmux-msg` | 完了。plugin 更新後は `${CLAUDE_PLUGIN_ROOT}/bin/` 経路指定が必要 |
| `kawaz/claude-nandakke` リポ作成 + claude 起動 | implemented | 推定 | 2026-06-17 | セッション末尾 (bare+worktree 構造で作成) | jjwt にも 1 個起動依頼あり (完了確認未) |
| `docs/issue/` の 2 件 (suspend/resume 多重描画 / session labels) が別 branch `quossnmz` に待機 | spoken | 推定 | 2026-06-17 | `docs/issue/2026-06-14-bug-suspend-resume-multidraw-claude-tui.md` / `docs/issue/2026-06-16-feature-session-labels.md` | kawaz 整理待ち |
| ICANON chunk 化 issue (open) | spoken | 推定 | 2026-06-17 | 未起票 | 要起票 or 次セッション着手 |
| ack test cover 拡張 issue (open) | spoken | 推定 | 2026-06-17 | 未起票 | 要起票 or 次セッション着手 |

---

## 補足: 解釈に迷った点

### 1. topic の粒度 — bug fix とその regression を分けるか

今回のセッションは「Enter 落ち bug 発見 → ack 実装 → regression 発覚 → poll(2) 方式で修正」という
1 本のストーリーだが、regression は「修正の結果生まれた別の bug」なので別 topic として切り出した。
読み返したとき「ack 入れた結果 python で壊れた」という文脈を索引で掴めるようにするため。

### 2. 「implemented」と「事実」の基準

セッション内で CI success + release まで通っているものは「implemented + 事実」とした。
`kawaz/claude-nandakke` リポ作成と jjwt 起動については「セッション末尾で着手中の background タスク」
として完了が確認できなかったため「推定」とした。

### 3. auto-lock 議論の相

「wait 中 lock 保持か解放か」の議論は codex + Workflow 4-plan で検討し、保持 (案 B) を選択、
実装 + DR-0022 まで到達している。議論の部分は「recorded」、実装完了分は「implemented」と分けて
書く方が正確だが、1 行にまとめるために「recorded (設計判断の記録) + 実装への参照」の形にした。

### 4. cmux-msg subscribe の落ちと復旧の相

plugin update に伴う subscribe の中断と復旧は「出来事」であり「決定」ではない。
ただし「`${CLAUDE_PLUGIN_ROOT}/bin/cmux-msg` 経由指定が必要」という運用知識が得られたので
記録した。相としては implemented (復旧完了) だが、next は「次回も同じ落ちが起きたら同じ手順」
という意味でもある。

### 5. 未起票 issue の扱い

ICANON chunk 化と ack test cover 拡張は「セッション内で言及されたが issue 未起票」。
索引の目的 (数日後に「これどうなってた?」を解消) から考えると、
未起票 = 追跡手段がないので索引に書くことで補完する意義がある、と判断して記録した。

---

## 補足: 自分の作業手順

1. 必須ドキュメント 3 件を先に並列 Read (DR-0001 / ROADMAP / decisions-log)
2. jsonl のサイズ (2.4 MB / 1469 行) を確認した上で全文読みを避ける方針を決定
3. `jq -r 'select(.type=="user") | .message.content'` でユーザー発言 → head -120 で冒頭把握
4. `jq -r 'select(.type=="assistant") | .message.content[] | select(.type=="text") | .text'` でアシスタントテキストのみ → head -200 で流れ把握
5. 同コマンドで tail -300 (後半) を取り、セッション終端の状態を確認
6. セッション期間 (timestamp) を確認して日付を特定
7. ユーザー発言のみ文字列抽出で kawaz の指示内容と方針決定を確認
8. 既存の agent-01.md を読んで出力フォーマットを合わせた
9. 索引 + 解釈メモ + 作業手順を書いて完了

### 選択した観点

他エージェントが同じ jsonl を扱う比較実験なので、自分の解釈を優先した。特に:

- **個別 bug fix より「このセッションで確定した設計方針」を重視**: PTY drain ack の完了点定義、
  auto-lock の wait 中保持という判断は「数日後に見て意味がある」情報として扱った
- **「未起票 issue」を積極的に索引に入れた**: 索引が「追跡できないものを追跡する」機能を持てば
  Phase 1 の検証価値が上がると考えた
- **regression を別 topic として立てた**: 「修正したら壊れた」という情報は実装の理解に重要で、
  索引からその経緯に辿れるようにした
