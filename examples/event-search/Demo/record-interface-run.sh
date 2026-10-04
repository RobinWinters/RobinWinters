#!/bin/bash
set -euo pipefail

# Run after build-for-testing. This records the real simulator framebuffer;
# it does not synthesize a walkthrough or alter the app's data or interactions.
: "${DEMO_SIMULATOR_UDID:?Select an existing compatible iPhone simulator first}"
mkdir -p .build/ui-evidence
xcrun simctl bootstatus "$DEMO_SIMULATOR_UDID" -b

video=.build/ui-evidence/native-interface-run.mp4
record_log=.build/ui-evidence/video-recorder.log
test_status=125
recorder_pid=

finish_recording() {
  local original_status=$?
  trap - EXIT
  if [ -n "$recorder_pid" ]; then
    kill -INT "$recorder_pid" 2>/dev/null || true
    wait "$recorder_pid" || true
  fi
  VIDEO_TEST_STATUS="$test_status" python3 - <<'PY'
import datetime, json, os
from pathlib import Path
video = Path('.build/ui-evidence/native-interface-run.mp4')
log = Path('.build/ui-evidence/video-recorder.log')
record = {
    'finishedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'sourceRevision': os.environ.get('GITHUB_SHA'),
    'simulatorUDID': os.environ['DEMO_SIMULATOR_UDID'],
    'testCommandExitCode': int(os.environ['VIDEO_TEST_STATUS']),
    'recordingStartedObserved': log.exists() and 'Recording started' in log.read_text(),
    'file': video.name,
    'bytes': video.stat().st_size if video.exists() else 0,
    'codecRequested': 'h264',
    'scope': 'Unedited simulator recording of synthetic public teaching-demo XCTest interactions; no private ShowFlex or physical-device footage',
    'playbackVerified': False
}
Path('.build/ui-evidence/video-recording.json').write_text(json.dumps(record, indent=2) + '\n')
print(json.dumps(record, indent=2))
PY
  exit "$original_status"
}
trap finish_recording EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

xcrun simctl io "$DEMO_SIMULATOR_UDID" recordVideo \
  --codec=h264 --mask=black "$video" > "$record_log" 2>&1 &
recorder_pid=$!

# Apple's simctl announces when the first frame has actually been processed.
for attempt in {1..20}; do
  if grep -q 'Recording started' "$record_log"; then break; fi
  if ! kill -0 "$recorder_pid" 2>/dev/null; then
    cat "$record_log"
    exit 1
  fi
  sleep 0.5
done
if ! grep -q 'Recording started' "$record_log"; then
  cat "$record_log"
  exit 1
fi

set +e
xcodebuild test-without-building \
  -project Demo/EventSearchDemo.xcodeproj \
  -scheme EventSearchDemo \
  -destination "platform=iOS Simulator,id=$DEMO_SIMULATOR_UDID" \
  -parallel-testing-enabled NO \
  -derivedDataPath .build/ui-testing \
  -resultBundlePath .build/ui-tests.xcresult \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tee .build/ui-test.log
test_status=${PIPESTATUS[0]}
set -e
exit "$test_status"
