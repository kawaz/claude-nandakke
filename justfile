# nandakke push / bump-version / validate
# (push-guard hook 経由でこの task を使うことで、直叩き block を回避)

# ---------- settings ----------

set positional-arguments

# ---------- main tasks ----------

# push (バージョン bump 済みを前提、全 gate 通過後に push してローカルも更新)
push: ensure-clean validate test check-versions check-outdated-translations
    bump-semver vcs push --branch main --jj-bookmark-auto-advance
    just on-success-release

# version を bump して Release commit を作成 (push は別途 `just push`)
[script]
bump-version bump="patch": ensure-clean
    new_version=$(bump-semver "$1" .claude-plugin/plugin.json .claude-plugin/marketplace.json --write --no-hint)
    bump-semver vcs commit -m "Release v${new_version}" .claude-plugin/plugin.json .claude-plugin/marketplace.json

# 現在の version を確認
version:
    @bump-semver get .claude-plugin/plugin.json .claude-plugin/marketplace.json --no-hint

# plugin spec を validate
validate:
    claude plugin validate .

# tests/ 配下のテストを実行 (0 件なら skip)
test:
    @for f in tests/*.test.sh; do [ -e "$f" ] || continue; bash "$f" || exit 1; done

# ---------- internal recipes (push の依存) ----------

# uncommitted change がない状態か確認 (git/jj-agnostic, DR-0020)
ensure-clean:
    bump-semver vcs is clean

# plugin.json と marketplace.json の version 一致を保証 (multi-file 整合性)
[private]
check-versions:
    @bump-semver get .claude-plugin/plugin.json .claude-plugin/marketplace.json --no-hint >/dev/null

# release 成功後の local 反映
on-success-release:
    @claude plugin marketplace update nandakke || echo "[warn] marketplace update 失敗。push は成功済み。'just on-success-release' で単独再実行可" >&2
    @claude plugin update nandakke@nandakke || echo "[warn] plugin update 失敗。push は成功済み。'just on-success-release' で単独再実行可" >&2
    @echo ""
    @echo "[hint] /reload-plugins to apply in this session without restart"

# 翻訳ペア (*-ja.md = 正本、*.md = 英訳) の commit-lag を検出 (= 正本 > 翻訳の場合エラー)
check-outdated-translations: ensure-clean
    bump-semver vcs outdated 'glob:**/*-ja.md' '$1/$2.md'

# 配布物 (skills/ hooks/ commands/) を持つようになったら check-version-bumped を追加する。
# 例: check-version-bumped: (_check-version-bumped "skills/" "hooks/" "commands/" "README.md" "README-ja.md")
