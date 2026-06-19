# Phase 1 試行: agent-07 (classroom-monitor iMessage セッション)

題材セッション: `66b917d2-43b1-4d3d-ab3d-2637200fadfb.jsonl`  
プロジェクト: `kawaz/classroom-monitor`  
セッション期間: 2026-06-18 14:07〜14:57 (JST)

---

## 記録層エントリ

| topic | 相 | 確信 | 最終言及 | 参照 | next |
|---|---|---|---|---|---|
| iMessage グループ送信の AppleScript chat_id 形式 (macOS Sonoma/Sequoia) | implemented | 事実 | 2026-06-18 | commit b05ee95, config/children.json | (完了。`any;+;<guid>` が正解, `iMessage;+;` は `-1728` エラー) |
| 連絡帳本文の取得方法 (post_id → base64 → 詳細 URL) | implemented | 事実 | 2026-06-18 | commit b05ee95, bin/classroom-monitor:78 `fetch_post_body` | (完了。`/u/N/c/<class>/mc/<base64>/details` + 8秒待ち) |
| imessage_targets 配列スキーマ (enabled/chat_id/text) | implemented | 事実 | 2026-06-18 | commit b05ee95, config/children.json | (完了。test=false/family=true で本番稼働中) |
| launchd 経由 osascript の Automation 許可 | implemented | 事実 | 2026-06-18 | セッション内の手動確認 14:47 | (完了。初回 launchd 起動時にダイアログ → OK で以降は不要) |
| process substitution の使い分け (launchd 環境) | recorded | 事実 | 2026-06-18 | commit ab4e146 (先行 fix), 今回の過剰修正 → 戻し | `jq --slurpfile <(...)` はNG, `while done < <(jq ...)` はOK — 混同注意 |
| b05ee95 の push が未実施 | spoken | 事実 | 2026-06-18 | git status (origin/main より 1 commit ahead) | `just push` or `git push` を明示実行する必要あり |
| 連絡帳本文の整形チューニング | spoken | 推定 | 2026-06-18 | セッション内「ヘッダが残ってる/本文が削れてる等あれば正規表現を調整」 | 実運用数日後に iMessage 届き内容を確認して調整判断 |
| u/N (マルチアカウント番号) の動的抽出 | implemented | 事実 | 2026-06-18 | commit b05ee95, fetch_post_body 関数内 | (完了。classroom セッションの現在 URL から動的抽出) |

---

## セッション全体の要約

classroom-monitor に iMessage 通知機能を追加したセッション。出発点は「iMessage CLIで送れるか？」という素朴な質問で、1セッション内で調査→設計→実装→実機テスト→本番稼働まで完走した。

主な発見・決定:
1. **chat_id 形式問題**: macOS Sonoma/Sequoia で `iMessage;+;<guid>` が `-1728` エラー → `any;+;<guid>` (chat.db の guid そのまま) が正解と実機確認
2. **連絡帳本文取得**: 一覧画面に本文なし → 詳細 URL (`post_id` を base64 encode) + domcontentloaded + 8秒待ちで取得確立
3. **worktree → main merge 完了**: b05ee95 が main HEAD、launchd から本番稼働

未完了: b05ee95 は push 未実施 (origin/main より 1 commit ahead)。

---

## 補足: 解釈に迷った点

### 1. chat_id の `iMessage;+;` は「間違い」か「macOS バージョン依存の既知問題」か
セッションでは「`any;+;` が正解」と実機確認したが、これは Sonoma/Sequoia 固有の挙動で以前の macOS では `iMessage;+;` で動いていた可能性がある。「事実」と記録したが、正確には「このバージョンの macOS では事実」であり、OS バージョンへの依存が確信の正確さを下げる。「確信」列の粒度として OS バージョン情報を含めるべきか迷った。

### 2. 「push 未実施」を topic として上げるべきか
push 未実施は「未着地決定」というよりただの未完了タスク。決定ではなく状態なのでスキーマに馴染みにくいが、「数日後に誰かがこのインデックスを見た時に push を忘れているとわかる」という観点で入れた。`next` 列に残タスクを書くか、別の管理方法がいいか迷った。

### 3. 1:1 chat の chat_id 形式 (`;-;` vs `buddy` 経由) の実運用状態
セッション中、1:1 は `buddy "+819040877395" of service "iMessage"` に切り替えた。config には `iMessage;-;+819040877395` が残っているが、コード内 (bin:38-44) で `;-;` の場合は buddy 経路に自動分岐している。この「config 表記と実際のプロトコル表記が乖離している」設計が後の混乱の元にならないか気になった。記録として残すべきか判断に迷い、省いた。

### 4. 「整形チューニング」の相をどう判断するか
「本文の切り出し範囲の正規表現を実運用で調整」は実際に動かしてみないと判断できない類の話で、「何が決定なのか」が曖昧。`spoken` + 推定で入れたが、これは「issue」「TODO」の方が適切な分類かもしれない。spoken/recorded/implemented の三相が「決定の着地」に特化していて、「まだ試していない調整」の置き場所として不自然な気がした。

### 5. セッション名に業務カテゴリ情報が含まれる
`sanitize-work-identifiers` ルールがあるが、このセッション自体は kawaz 個人の子育て支援ツールのような性格で、業務リポへの流出ではない。サニタイズ不要と判断したが「学校教育関連の話題」として引っかかる可能性があり迷った。結果として固有の人物名等は記録層に含めないよう一般化した。

---

## 補足: 自分の作業手順

1. 必須ファイル 3 件を並列 Read (DR-0001, ROADMAP, decisions-log 見本)
2. JSONL のサイズ・行数確認 (595行, 1.9MB)
3. `jq` でメッセージタイプ別の行数を集計して全体像を把握
4. ユーザーメッセージ全文を jq で抽出 → 会話の流れを把握 (何を作ろうとしているか)
5. アシスタントメッセージ全文を jq で抽出 → 決定・ハマり所・実機確認結果を抽出
6. git log と config/children.json の現在状態を確認して「実装済み」の実機裏取り
7. push 未実施を git status で事実確認
8. 6 列スキーマに落とし込みながら Write

**判断**: 「何を記録するか」の基準として「数日後に『これどうなってた?』となりそうなもの」を優先した。AppleScript の chat_id 形式と process substitution の使い分けは似た罠に再びはまる可能性が高いと判断して記録した。
