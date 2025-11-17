#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Download build artifacts from the latest successful CI run.

Options:
  --branch BRANCH     Branch to search (default: develop)
  --run-id ID         Download artifacts from a specific run ID instead of the latest successful run
  --workflow FILE     Workflow filename (default: ci.yml)
  --artifact NAME     Only download a specific artifact (default: download all artifacts from the run)
  --dest DIR          Directory to store artifacts (default: ./ci-artifacts)
  -h, --help          Show this help message

Prerequisites: GitHub CLI (gh) authenticated for this repository and jq installed.
USAGE
}

branch="develop"
run_id=""
workflow="ci.yml"
artifact_name=""
dest_dir="ci-artifacts"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      branch="$2"; shift 2;;
    --run-id)
      run_id="$2"; shift 2;;
    --workflow)
      workflow="$2"; shift 2;;
    --artifact)
      artifact_name="$2"; shift 2;;
    --dest)
      dest_dir="$2"; shift 2;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown option: $1" >&2
      usage; exit 1;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "The GitHub CLI (gh) is required." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required to parse GitHub API responses." >&2
  exit 1
fi

if [[ -z "$run_id" ]]; then
  run_id=$(gh run list --workflow "$workflow" --branch "$branch" --status completed --json databaseId,conclusion -q '
    map(select(.conclusion=="success"))
    | first
    | .databaseId
  ')
  if [[ -z "$run_id" ]]; then
    echo "No successful runs found for workflow '$workflow' on branch '$branch'." >&2
    exit 1
  fi
fi

echo "Downloading artifacts from run $run_id..."
mkdir -p "$dest_dir"

download_args=("--dir" "$dest_dir" "$run_id")
if [[ -n "$artifact_name" ]]; then
  download_args+=("--name" "$artifact_name")
fi

gh run download "${download_args[@]}"

echo "Artifacts saved to $dest_dir" 
