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

# The toolchain image, under the version the release stage just cut: the
# factory's own tag is the release line, and release-container pushed the
# image under that same number before this substage ran. This is what lets
# the pipeline's own jobs resolve their container from this register with
# nobody editing the pin, and a consumer register can copy the record from
# here rather than from a hand.
image_version=$(git -C "$ROOT/forge-self-factory" describe --tags --abbrev=0 2>/dev/null || true)
if [ -n "$image_version" ]; then
    forge-register publish --provenance "$PROVENANCE" \
        "internal:ghcr.io/alexandremahdhaoui/forge" "$image_version"
else
    echo "publish-members: forge-self-factory carries no tag yet; the image track waits for the first release"
fi

echo "publish-members: every member is on the internal track at $PROVENANCE"
