#!/bin/sh
set -eu

# Publish every toolchain member into the internal track, with the newest
# minted revision as provenance. The revision record pins each member's
# sha, so a consumer resolves the exact proven tuple with no version typed.
#
# The version label is the member's newest tag, or a dev label carrying the
# proven sha when no tag exists yet. The provenance record is what pins;
# the label is what humans read.

ROOT="${1:-..}"
STATE="$ROOT/forge-self-state/revisions"

[ -d "$STATE" ] || { echo "publish-members: no revisions at $STATE; run the workspace pipeline first" >&2; exit 1; }

RECORD=$(grep -l '"forge"' "$STATE"/*.json 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
[ -n "$RECORD" ] || { echo "publish-members: no revision covers the toolchain; run the workspace pipeline first" >&2; exit 1; }

PROVENANCE=$(basename "$RECORD" .json)
echo "publish-members: provenance $PROVENANCE"

publish() {
    repo="$1"

    version=$(git -C "$ROOT/$repo" describe --tags --abbrev=0 2>/dev/null || true)
    if [ -z "$version" ]; then
        count=$(printf %08d "$(git -C "$ROOT/$repo" rev-list --count HEAD)")
        sha=$(git -C "$ROOT/$repo" rev-parse --short=12 HEAD)
        version="v0.1.0-dev.r$count.g$sha"
    fi

    forge-register publish --provenance "$PROVENANCE" \
        --source "git@github.com:alexandremahdhaoui/$repo.git" \
        "internal:github.com/alexandremahdhaoui/$repo" "$version"
}

for repo in forge forge-ci forge-factory forge-register \
    forge-ci-spec forge-revision-spec forge-register-spec; do
    publish "$repo"
done

echo "publish-members: every member is on the internal track at $PROVENANCE"
