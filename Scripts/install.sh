#!/usr/bin/env bash
# Installs a tagged or branched version of stahpwatch on your connected iPhone,
# over the existing app, so its data (Looks, settings, a running stopwatch) stays.
#
#   ./Scripts/install.sh v1.1                  # your connected iPhone
#   ./Scripts/install.sh tap-to-start          # a branch
#   ./Scripts/install.sh v1.1 --device <UDID>  # a specific iPhone
#   ./Scripts/install.sh v1.1 --simulator      # the booted Simulator instead
#
# It builds in a temporary git worktree, so your working folder and its
# uncommitted changes are never touched. Signing comes from Config/Local.xcconfig.
#
# Going back to an older version keeps your data, but an older version only
# understands settings in its own format:
# - v1.1 replaces all saved Looks with a fresh "Look 1" if any Look uses
#   something it doesn't know, such as a dial style added later. It also drops
#   Look fields it doesn't know every time it opens.
# - Versions before Looks ignore saved Looks but leave them in place, so they
#   come back when you install a newer version again.
# - A running or paused stopwatch and the Dim Timer carry over in both directions.
set -euo pipefail

usage() {
    sed -n '2,10s/^# \{0,1\}//p' "$0"
    exit 1
}

[[ $# -ge 1 ]] || usage
ref=$1
shift
target=device
udid=
while [[ $# -gt 0 ]]; do
    case $1 in
        --simulator) target=simulator; shift ;;
        --device) udid=${2:-}; [[ -n $udid ]] || usage; shift 2 ;;
        *) usage ;;
    esac
done

repo=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
bundle_id=com.jacobtehrani.stahpwatch

fail() { echo "install.sh: $*" >&2; exit 1; }

commit=$(git -C "$repo" rev-parse --verify --quiet "$ref^{commit}") \
    || fail "'$ref' isn't a tag, branch or commit in this repository"

xcodegen=$(command -v xcodegen || true)
[[ -n $xcodegen ]] || xcodegen="$repo/.tools/xcodegen/bin/xcodegen"
[[ -x $xcodegen ]] || fail "XcodeGen not found; run 'brew install xcodegen'"

if [[ $target == device ]]; then
    [[ -f $repo/Config/Local.xcconfig ]] \
        || fail "Config/Local.xcconfig is missing; copy Config/Local.xcconfig.example and add your Team ID"
    if [[ -z $udid ]]; then
        devices_json=$(mktemp)
        xcrun devicectl list devices --json-output "$devices_json" >/dev/null 2>&1 || true
        udid=$(/usr/bin/python3 - "$devices_json" <<'EOF'
import json, sys
try:
    devices = json.load(open(sys.argv[1]))["result"]["devices"]
except Exception:
    devices = []
for d in devices:
    hw, conn = d.get("hardwareProperties", {}), d.get("connectionProperties", {})
    if hw.get("reality") == "physical" and hw.get("platform") == "iOS" \
            and conn.get("tunnelState") == "connected" and hw.get("udid"):
        print(hw["udid"])
        break
EOF
)
        rm -f "$devices_json"
        [[ -n $udid ]] || fail "no connected iPhone found; plug it in, unlock it and try again"
    fi
else
    udid=$(xcrun simctl list devices booted | sed -n 's/.*(\([0-9A-F-]\{36\}\)) (Booted).*/\1/p' | head -1)
    [[ -n $udid ]] || fail "no booted Simulator; open the Simulator app first"
fi

worktree=$(mktemp -d "${TMPDIR:-/tmp}/stahpwatch-install.XXXXXX")
cleanup() {
    git -C "$repo" worktree remove --force "$worktree" >/dev/null 2>&1 || rm -rf "$worktree"
    git -C "$repo" worktree prune
}
trap cleanup EXIT

echo "==> Checking out $ref ($(git -C "$repo" rev-parse --short "$commit")) in a temporary worktree"
git -C "$repo" worktree add --quiet --detach "$worktree" "$commit"
if [[ -f $repo/Config/Local.xcconfig ]]; then
    cp "$repo/Config/Local.xcconfig" "$worktree/Config/Local.xcconfig"
fi

echo "==> Generating the Xcode project"
(cd "$worktree" && "$xcodegen" generate --quiet)

if [[ $target == device ]]; then
    destination="id=$udid"
    products=Debug-iphoneos
    signing=(-allowProvisioningUpdates -allowProvisioningDeviceRegistration)
else
    destination="platform=iOS Simulator,id=$udid"
    products=Debug-iphonesimulator
    signing=()
fi

echo "==> Building (this takes a minute or two)"
log="$worktree/build.log"
if ! xcodebuild -project "$worktree/stahpwatch.xcodeproj" -scheme stahpwatch -configuration Debug \
        -destination "$destination" -derivedDataPath "$worktree/build" ${signing[@]+"${signing[@]}"} build \
        >"$log" 2>&1; then
    grep -E 'error:|BUILD FAILED' "$log" | sort -u | head -20 >&2
    fail "build failed"
fi
app="$worktree/build/Build/Products/$products/stahpwatch.app"

echo "==> Installing over the existing app"
if [[ $target == device ]]; then
    xcrun devicectl device install app --device "$udid" "$app" >/dev/null
    xcrun devicectl device process launch --device "$udid" "$bundle_id" >/dev/null \
        || echo "Installed, but it couldn't be opened. If iOS says the developer isn't trusted, go to Settings > General > VPN & Device Management."
else
    xcrun simctl terminate "$udid" "$bundle_id" >/dev/null 2>&1 || true
    xcrun simctl install "$udid" "$app"
    xcrun simctl launch "$udid" "$bundle_id" >/dev/null
fi

echo "==> Installed stahpwatch $ref on the $target"
