#!/usr/bin/env bash
#
# promote-dashboard.sh — fast-forward the `release` branch to current master,
# but only after verifying the prod API is serving the matching PairQL
# contract hash. This is the one extra line tacked onto the API prod-deploy
# ritual: after the API binary is restarted in production, run this.
#
# Behavior:
#   1. Sync `origin/master` and `origin/release`.
#   2. If they're equal, exit 0 (no-op).
#   3. Read the expected contract hash from master's contract.ts.
#   4. Poll the prod API until its contract hash matches (or timeout).
#   5. Push master's SHA to `release`. Cloudflare Pages deploys it.
#
# Exit codes:
#   0  promoted, or already promoted
#   1  setup error (file missing, jq/curl missing, git fetch failed, …)
#   2  prod API never converged on expected hash within timeout
#
# Env overrides (defaults shown):
#   PROD_API=https://api.gertrude.app
#   REMOTE=origin
#   RELEASE_BRANCH=release
#   CONTRACT_FILE=web/shared/pairql/src/dashboard/contract.ts
#   TIMEOUT_SECONDS=180
#   POLL_INTERVAL=5

set -euo pipefail

PROD_API="${PROD_API:-https://api.gertrude.app}"
REMOTE="${REMOTE:-origin}"
RELEASE_BRANCH="${RELEASE_BRANCH:-release}"
CONTRACT_FILE="${CONTRACT_FILE:-web/shared/pairql/src/dashboard/contract.ts}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"
POLL_INTERVAL="${POLL_INTERVAL:-5}"

die()   { echo "ERROR: $*" >&2; exit "${2:-1}"; }
log()   { echo "==> $*"; }
short() { echo "${1:0:12}"; }

command -v curl >/dev/null || die "curl not found"
command -v git  >/dev/null || die "git not found"

log "Fetching ${REMOTE}/master and ${REMOTE}/${RELEASE_BRANCH}…"
git fetch --quiet "${REMOTE}" master "+refs/heads/${RELEASE_BRANCH}:refs/remotes/${REMOTE}/${RELEASE_BRANCH}" 2>/dev/null \
  || git fetch --quiet "${REMOTE}" master

MASTER_SHA=$(git rev-parse "${REMOTE}/master")
RELEASE_SHA=$(git rev-parse "${REMOTE}/${RELEASE_BRANCH}" 2>/dev/null || echo "")

if [ -n "${RELEASE_SHA}" ] && [ "${MASTER_SHA}" = "${RELEASE_SHA}" ]; then
  log "${RELEASE_BRANCH} is already at $(short "${MASTER_SHA}"). Nothing to do."
  exit 0
fi

EXPECTED_HASH=$(git show "${MASTER_SHA}:${CONTRACT_FILE}" 2>/dev/null \
  | grep -oE '[0-9a-f]{64}' | head -1 || true)
[ -n "${EXPECTED_HASH}" ] || die "could not read contract hash from ${CONTRACT_FILE} at $(short "${MASTER_SHA}")"

log "Expected prod contract hash: $(short "${EXPECTED_HASH}")…"
log "Polling ${PROD_API}/dashboard-pairql-contract-hash (timeout ${TIMEOUT_SECONDS}s)…"

elapsed=0
prod_hash=""
while [ "${elapsed}" -lt "${TIMEOUT_SECONDS}" ]; do
  prod_hash=$(curl -fsSL --max-time 10 "${PROD_API}/dashboard-pairql-contract-hash" 2>/dev/null || echo "")
  if [ "${prod_hash}" = "${EXPECTED_HASH}" ]; then
    log "Match. Prod API is on expected contract."
    break
  fi
  prod_display=$([ -n "${prod_hash}" ] && short "${prod_hash}" || echo "(none)")
  echo "    prod=${prod_display}… expected=$(short "${EXPECTED_HASH}")… (sleep ${POLL_INTERVAL}s)"
  sleep "${POLL_INTERVAL}"
  elapsed=$((elapsed + POLL_INTERVAL))
done

if [ "${prod_hash}" != "${EXPECTED_HASH}" ]; then
  cat >&2 <<EOF
ERROR: prod API never reported the expected contract hash within ${TIMEOUT_SECONDS}s.
       expected: ${EXPECTED_HASH}
       got:      ${prod_hash:-<none>}
Did the API prod cutover actually run? Aborting dashboard promote.
EOF
  exit 2
fi

log "Pushing $(short "${MASTER_SHA}") to ${REMOTE}/${RELEASE_BRANCH}…"
git push "${REMOTE}" "${MASTER_SHA}:refs/heads/${RELEASE_BRANCH}"

log "Done. Cloudflare Pages will deploy $(short "${MASTER_SHA}")."
