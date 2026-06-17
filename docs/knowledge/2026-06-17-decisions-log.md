# decisions-log (Phase 1 試作)

DR-0001 §YAGNI Phase 1「記録層を手動で回す」の試作。本ファイルそのものが
nandakke が将来生成する「中央記録層」の人手シミュレーション。

**目的**: 索引が「数日後のこれどうなってた?」を実際に減らすかを検証する。
効かなければ ROADMAP の上位段に進まない (= 自動化や追跡セッション化の土台がない)。

## スキーマ (DR-0001 §索引スキーマ)

| 列 | 内容 |
|---|---|
| topic | 決定・議論の主題 |
| 相 | spoken / recorded / implemented |
| 確信 | 事実 (機械確認済) / 推定 |
| 最終言及 | 最後に触れた時点 (実装では messageid/timestamp) |
| 参照 | セッション uri / ファイルパス等のポインタ (内容は重複させない) |
| next | 次に進めるべき相、または確認手段 |

`確信` 列の運用: 推定と事実を混同しない。相を倒すのは事実が取れた時だけ
(= 機械確認・実コードを見た等)。

## 運用ルール (試作版)

- 各セッションの振り返り時に未着地決定を相つきで挙げ、ここに追記する
- **本ファイルは索引** (= ポインタ集)。内容のコピーは置かない (参照先を辿る)
- 「最終言及」は ISO 日付で十分 (= 試作段階。実装では messageid を使う)
- 行が増えて読みづらくなったら `archive/` 退避や topic 別ファイル分割を検討
- 検証ポイント: 数日後にこの索引を見て「あれどうなってた?」が解消するか

## 索引

| topic | 相 | 確信 | 最終言及 | 参照 | next |
|---|---|---|---|---|---|
| 知識索引化サイドカーのアーキテクチャ | recorded | 事実 | 2026-06-17 | [DR-0001](../decisions/DR-0001-knowledge-index-sidecar-architecture.md) | Phase 1 検証 (本索引そのもの) |
| プラグイン名 = `nandakke` | recorded | 事実 | 2026-06-17 | [DR-0001 §7](../decisions/DR-0001-knowledge-index-sidecar-architecture.md#7-プラグイン名--nandakke-確定-2026-06-17) / [ROADMAP](../ROADMAP.md#未決事項-phase-進行のブロッカー) | (完了。DR §7 確定済み、命名根拠も記録) |
| 中央記録層の永続化形式 (DB / file) | spoken | 推定 | 2026-06-17 | [DR-0001 §6](../decisions/DR-0001-knowledge-index-sidecar-architecture.md#未検証--未決-6) | cmux-msg の inotify 配信判断の結論を流用 (= cmux-msg 側を読みに行く) |
| CSA messageid 以降指定の差分供給 | spoken | 推定 | 2026-06-17 | [DR-0001 §6](../decisions/DR-0001-knowledge-index-sidecar-architecture.md#未検証--未決-6) | Phase 3 着手時に検証 (= 実機で `claude-session-analysis` skill を試す) |
| UserPromptSubmit で turn 拒否 + 回答非同期化 | recorded | 事実 | 2026-06-17 | [DR-0001 §フック仕様の裏取り](../decisions/DR-0001-knowledge-index-sidecar-architecture.md#フック仕様の裏取り-claude-plugin-reference-hooksmd-v21170) | Phase 4 着手時にフック実装 (= `hooks/` ディレクトリ追加) |
| プラグイン manifest 配置 | implemented | 事実 | 2026-06-17 | [.claude-plugin/](../../.claude-plugin/) | (完了) |
| 翻訳ガード justfile | implemented | 事実 | 2026-06-17 | [justfile](../../justfile) | (完了。trigger paths 配布物追加時に拡張) |
