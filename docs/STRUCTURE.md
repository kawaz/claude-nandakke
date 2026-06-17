# リポジトリ物理構造

実装前 (DR-0001 §YAGNI 段階導入)。`src/` `tests/` `justfile` 等の実装系は
段階導入のフェーズが進んだ時点で配置する。現時点では docs スケルトンのみ。

```
claude-nandakke/
  README.md / README-ja.md
  LICENSE
  docs/
    DESIGN.md / DESIGN-ja.md
    STRUCTURE.md          (本ファイル)
    ROADMAP.md
    decisions/
      INDEX.md
      DR-0001-knowledge-index-sidecar-architecture.md
    journal/              (作業の生記録。並列セッション時に有用)
    findings/             (単発調査の確定事実)
    issue/                (TODO / 受領依頼)
    runbooks/             (運用フェーズ入り時)
    knowledge/            (時系列依存しない長期ナレッジ)
    research/             (中期テーマの深掘り)
    design/               (DESIGN.md で収まらない付随詳細)
```

サブディレクトリは必要になった時点で作る (空ディレクトリは置かない)。

## 配置予定 (実装段階で追加)

- `justfile` — task runner (canonical, docs-structure 参照)
- `.claude-plugin/plugin.json` — Claude Code plugin manifest
- `.claude-plugin/marketplace.json` — marketplace 自己宣言
- `hooks/` — UserPromptSubmit hook 等
- `skills/` — 索引参照 skill
- `src/` または `bin/` — 言語選定後

ROADMAP.md の段階に合わせて追加する。
