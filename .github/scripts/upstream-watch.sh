#!/usr/bin/env bash
# Compares jonhoo/rust-imap with .github/upstream-reviewed. When upstream main
# or a tag has moved, opens (or refreshes) one pull request that rewrites that
# file and lists what changed. Merging it records the review and changes
# nothing else; porting an upstream fix is its own pull request with tests.
#
# Runs in GitHub Actions from a checkout of the fork's default branch, with a
# GH_TOKEN allowed to push branches and open pull requests.
set -euo pipefail
export LC_ALL=C

upstream=https://github.com/jonhoo/rust-imap
marker=.github/upstream-reviewed
pr_branch=upstream-watch
repo=${GITHUB_REPOSITORY:?}
base=${GITHUB_REF_NAME:?}
# The files this fork patches: an upstream commit touching one deserves a close look.
patched='^src/(client|error|parse)\.rs$|^src/extensions/idle\.rs$'

# "<commit> <ref>" for upstream main and every tag, annotated tags peeled.
current=$(git ls-remote "$upstream.git" refs/heads/main 'refs/tags/*' | awk '
  { sha = $1; ref = $2 }
  ref ~ /\^\{\}$/ { sub(/\^\{\}$/, "", ref); peeled[ref] = sha; next }
  { plain[ref] = sha }
  END { for (r in plain) print ((r in peeled) ? peeled[r] : plain[r]), r }' | sort -k2,2)
reviewed=$(grep -v '^#' "$marker" || true)

new=$(comm -13 <(sort <<<"$reviewed") <(sort <<<"$current"))
if [ -z "$new" ]; then
  echo "Upstream has nothing this fork has not reviewed."
  exit 0
fi

ref_commit() { awk -v ref="$2" '$2 == ref { print $1 }' <<<"$1"; }

body=$(mktemp)
{
  echo "[jonhoo/rust-imap]($upstream) has moved past \`$marker\`. Merging this pull request records the changes below as reviewed and changes nothing else."
  echo
  echo "Port anything worth having in its own pull request with tests, then bump the \`rev\` EmailOps pins."

  old_main=$(ref_commit "$reviewed" refs/heads/main)
  new_main=$(ref_commit "$current" refs/heads/main)
  if [ "$old_main" != "$new_main" ]; then
    git fetch --quiet --no-tags "$upstream.git" main
    echo
    echo "### Upstream \`main\`"
    echo
    if git merge-base --is-ancestor "$old_main" "$new_main" 2>/dev/null; then
      git log --reverse --format='%H %s' "$old_main..$new_main" | while read -r sha subject; do
        # Inside a code span the subject can neither mention anyone nor link an issue here.
        subject=$(tr '\140' "'" <<<"$subject")
        line="- [\`${sha:0:8}\`]($upstream/commit/$sha) \`$subject\`"
        files=$(git diff-tree --no-commit-id --name-only -r "$sha" | grep -E "$patched" | paste -sd ' ' - || true)
        if [ -n "$files" ]; then
          line="$line: **touches a file this fork patches** ($files)"
        fi
        echo "$line"
      done
    else
      echo "History was rewritten: \`main\` moved from \`${old_main:0:8}\` to [\`${new_main:0:8}\`]($upstream/commit/$new_main)."
    fi
  fi

  tags=$(awk '$2 ~ /^refs\/tags\// { sub(/^refs\/tags\//, "", $2); print $2, $1 }' <<<"$new")
  if [ -n "$tags" ]; then
    echo
    echo "### New or moved tags"
    echo
    while read -r tag sha; do
      echo "- \`$tag\` at [\`${sha:0:8}\`]($upstream/commit/$sha)"
    done <<<"$tags"
  fi
} >"$body"

{ grep '^#' "$marker" || true; echo "$current"; } >"$marker.new"
mv "$marker.new" "$marker"
git switch --quiet -C "$pr_branch"
git add "$marker"
git -c user.name='github-actions[bot]' -c user.email='41898282+github-actions[bot]@users.noreply.github.com' \
  commit --quiet -m "chore: record upstream rust-imap refs as reviewed"
git push --quiet --force origin "$pr_branch"

if [ "$(gh pr view "$pr_branch" --repo "$repo" --json state --jq .state 2>/dev/null || true)" = OPEN ]; then
  gh pr edit "$pr_branch" --repo "$repo" --body-file "$body"
else
  gh pr create --repo "$repo" --base "$base" --head "$pr_branch" \
    --title "Review upstream rust-imap changes" --body-file "$body"
fi
