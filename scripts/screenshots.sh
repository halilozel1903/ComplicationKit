#!/usr/bin/env bash
# Captures README screenshots of the example app on an Apple Watch simulator.
# Usage: scripts/screenshots.sh <Scheme> <bundle id> <scene> [<scene> ...]
# Writes docs/screenshots/watch-<scene>.png, for example watch-circular.png and watch-face.png.
# The app writes tmp/screenshot-ready once a scene is on screen; the script waits for that marker and
# exits with an error instead of keeping a blank, stale or watch face capture.
set -euo pipefail

SCHEME="$1"; BUNDLE_ID="$2"; shift 2
if [ $# -eq 0 ]; then
  echo "No scenes given" >&2
  exit 1
fi
PROJECT="Example/ComplicationDemo.xcodeproj"
OUT="docs/screenshots"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

# Watch captures are small and mostly black, so a file size threshold cannot tell a blank frame from a real one.
# A small checker looks at the image size and colour variety instead.
xcrun swiftc -O scripts/check-screenshot.swift -o "$TMP/check-screenshot"

# A watchOS simulator runtime is needed to build and run; download it if the runner has none.
if ! xcrun simctl list runtimes available -j | jq -e '[.runtimes[] | select(.name | test("watchOS"))] | length > 0' > /dev/null; then
  echo "No watchOS simulator runtime installed, downloading one"
  xcodebuild -downloadPlatform watchOS
fi

# Ranks Apple Watch names: the newest "Series", then the newest "Ultra", then any other model; bigger cases first.
# The gallery draws complications at their real size for 46mm and 49mm watches, so a big case is preferred.
RANK='
  def model: [scan("(?:Series|Ultra|SE) ([0-9]+)")] | (.[0][0] // "0") | tonumber;
  def size: [scan("([0-9]+)mm")] | (.[0][0] // "0") | tonumber;
  def family: if test("Series") then 2 elif test("Ultra") then 1 else 0 end;
  def rank: [(.name | family), (.name | model), (.name | size)];
'

# pick_watch: the best available Apple Watch on the newest watchOS runtime. Creates one when none exists.
pick_watch() {
  local udid runtime device_type
  udid=$(xcrun simctl list devices available -j | jq -r "$RANK"'
    [.devices | to_entries[] | select(.key | test("watchOS"))
      | (.key | [scan("[0-9]+")] | map(tonumber)) as $version
      | .value[] | select(.name | test("^Apple Watch"))
      | . + {order: ([$version] + rank)}]
    | sort_by(.order) | last | .udid // empty')
  if [ -n "$udid" ]; then echo "$udid"; return; fi
  runtime=$(xcrun simctl list runtimes available -j | jq -r '
    [.runtimes[] | select(.name | test("watchOS"))] | sort_by(.version | split(".") | map(tonumber)) | last | .identifier // empty')
  if [ -z "$runtime" ]; then
    echo "No watchOS simulator runtime available" >&2
    exit 1
  fi
  for device_type in $(xcrun simctl list devicetypes -j | jq -r "$RANK"'
    [.devicetypes[] | select(.name | test("^Apple Watch")) | . + {order: rank}] | sort_by(.order) | reverse | .[].identifier'); do
    if udid=$(xcrun simctl create "Screenshots Apple Watch" "$device_type" "$runtime" 2>/dev/null); then
      echo "$udid"
      return
    fi
  done
  echo "Could not create an Apple Watch simulator" >&2
  exit 1
}

UDID="$(pick_watch)"
if [ -z "$UDID" ]; then
  echo "No Apple Watch simulator available" >&2
  exit 1
fi
echo "Using simulator $UDID"
xcrun simctl list devices -j | jq -r --arg udid "$UDID" '.devices[][] | select(.udid == $udid) | "Device: \(.name)"'

xcodebuild build \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$UDID" \
  -derivedDataPath build/watch \
  CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO DEVELOPMENT_TEAM= | tail -n 5

APP="$(find build/watch/Build/Products -maxdepth 2 -name "$SCHEME.app" | head -n 1)"
if [ -z "$APP" ]; then
  echo "Build product $SCHEME.app not found" >&2
  exit 1
fi

# valid_capture <file> <watch face capture> <previous capture or empty>
# Rejects blank or launching frames (the checker), a capture identical to the watch face (the app never came to the
# front) and one identical to the previous scene (the app never switched).
valid_capture() {
  local file="$1" home="$2" previous="$3"
  [ -s "$file" ] || return 1
  "$TMP/check-screenshot" "$file" || return 1
  if cmp -s "$file" "$home"; then
    return 1
  fi
  if [ -n "$previous" ] && cmp -s "$file" "$previous"; then
    return 1
  fi
  return 0
}

xcrun simctl shutdown all > /dev/null 2>&1 || true
xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl install "$UDID" "$APP"
CONTAINER="$(xcrun simctl get_app_container "$UDID" "$BUNDLE_ID" data)"

# A first boot can still be setting up the watch face; give it time, then keep a capture of it so a frame where
# the app never came to the front is rejected.
sleep 10
HOME_CAPTURE="$TMP/home.png"
xcrun simctl io "$UDID" screenshot "$HOME_CAPTURE"

previous=""
for scene in "$@"; do
  file="$OUT/watch-$scene.png"
  capture="$TMP/watch-$scene.png"
  ok=""
  for attempt in 1 2 3; do
    xcrun simctl terminate "$UDID" "$BUNDLE_ID" 2>/dev/null || true
    sleep 1
    rm -f "$CONTAINER/tmp/screenshot-ready"
    if ! xcrun simctl launch "$UDID" "$BUNDLE_ID" -screenshot "$scene"; then
      echo "Could not launch the app for $scene (attempt $attempt), retrying"
      continue
    fi
    # The app writes this marker once the scene is on screen.
    waited=0
    while [ ! -f "$CONTAINER/tmp/screenshot-ready" ] && [ "$waited" -lt 90 ]; do
      sleep 1
      waited=$((waited + 1))
    done
    if [ ! -f "$CONTAINER/tmp/screenshot-ready" ]; then
      echo "The app did not show $scene (attempt $attempt), retrying"
      continue
    fi
    # Nothing in the gallery animates, but the system can still be fading the app in after a launch.
    sleep $((3 + attempt * 2))
    rm -f "$capture"
    xcrun simctl io "$UDID" screenshot "$capture"
    if valid_capture "$capture" "$HOME_CAPTURE" "$previous"; then
      ok=1
      break
    fi
    echo "Blank, stale or watch face capture for $scene (attempt $attempt), retrying"
  done
  if [ -z "$ok" ]; then
    echo "Capture for watch-$scene is still broken; refusing to commit a bad screenshot." >&2
    exit 1
  fi
  mv "$capture" "$file"
  previous="$file"
  echo "Captured $file ($(wc -c < "$file") bytes)"
done

xcrun simctl shutdown "$UDID" || true
