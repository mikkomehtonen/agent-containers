#!/usr/bin/env bash
# Smoke test for the browser tooling baked into the agent-base image:
#   1. agent-browser CLI launches its browser and loads a page
#   2. Playwright's Chromium launches headless and loads a page
#
# Run from inside a container built on agent-base:
#   bash base/browser-smoke-test.sh [url]     (default: https://example.com)
set -euo pipefail

URL="${1:-https://example.com}"
fail() { echo "FAIL: $1" >&2; exit 1; }

echo "== agent-browser =="
agent-browser open "$URL" >/dev/null || fail "agent-browser open $URL"
[ -n "$(agent-browser get title)" ] || fail "agent-browser get title"
agent-browser snapshot >/dev/null || fail "agent-browser snapshot"
agent-browser close >/dev/null || true
echo "OK: agent-browser"

echo "== playwright =="
NODE_PATH="$(npm root -g)" node -e '
  const { chromium } = require("playwright");
  (async () => {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto(process.argv[1], { waitUntil: "load" });
    const title = await page.title();
    if (!title) throw new Error("page has no title");
    console.log("title:", title);
    await browser.close();
  })().catch((e) => { console.error(e.message); process.exit(1); });
' "$URL" || fail "playwright chromium $URL"
echo "OK: playwright"

echo "All browser checks passed"