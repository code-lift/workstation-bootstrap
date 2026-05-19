#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_REPO="${WST_BOOTSTRAP_REPO:-code-lift/workstation-bootstrap}"
WORKSTATION_BUNDLE_URL="${WORKSTATION_BUNDLE_URL:-}"
WST_RELEASE="latest"
bootstrap_args=()
APT_UPDATED=false

usage() {
  cat <<'USAGE'
Usage:
  install.sh [--apply] [--yes] [--version <tag>] [setup options...] [--help]

Setup (one-time, if not already done):
  gh auth login

Download and run:
  gh release download latest --repo code-lift/workstation-bootstrap \
    --pattern install.sh -D /tmp/ --clobber
  bash /tmp/install.sh           # preview
  bash /tmp/install.sh --apply   # apply

Inspect first:
  gh release download latest --repo code-lift/workstation-bootstrap \
    --pattern install.sh -D /tmp/ --clobber
  less /tmp/install.sh
  bash /tmp/install.sh --apply

Default:
  Preview mode. Downloads the setup bundle and shows what will happen without changing this computer.

Options:
  --apply                 Apply the selected setup.
  --yes                   Pass through automation confirmation.
  --version <tag>         Install a specific release (e.g. v1.0.0). Default: latest.
  --help                  Show this help.

Environment:
  WORKSTATION_BUNDLE_URL  Override with a local file:// path for testing.
  WST_BOOTSTRAP_REPO      Override the bootstrap repository.

USAGE
}

ensure_gh_auth() {
  if ! command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI (gh) is required to download the setup bundle." >&2
    echo "Install from: https://cli.github.com" >&2
    return 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    echo "GitHub authentication required to download the setup bundle." >&2
    echo "Run: gh auth login" >&2
    return 1
  fi
}

download_bundle() {
  local zip_path="$1"
  local sums_path="$2"
  local output_dir
  output_dir="$(dirname "$zip_path")"

  if [[ -n "$WORKSTATION_BUNDLE_URL" ]]; then
    if [[ "$WORKSTATION_BUNDLE_URL" != file://* ]]; then
      echo "[warn] WORKSTATION_BUNDLE_URL must be a file:// path. Ignoring." >&2
    else
      local local_path="${WORKSTATION_BUNDLE_URL#file://}"
      cp "$local_path" "$zip_path"
      local local_sums
      local_sums="$(dirname "$local_path")/SHA256SUMS"
      if [[ -f "$local_sums" ]]; then cp "$local_sums" "$sums_path"; fi
      return
    fi
  fi

  ensure_gh_auth || return 1
  gh release download "$WST_RELEASE" \
    --repo "$BOOTSTRAP_REPO" \
    --pattern 'workstation-bootstrap.zip' \
    --pattern 'SHA256SUMS' \
    --dir "$output_dir" \
    --clobber || {
    echo "Failed to download release '${WST_RELEASE}' from ${BOOTSTRAP_REPO}." >&2
    echo "Check available releases: gh release list --repo ${BOOTSTRAP_REPO}" >&2
    return 1
  }
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo "$@"
    return
  fi

  echo "Administrator permission is required for setup prerequisites." >&2
  echo "Install sudo or run this setup from an administrator/root shell." >&2
  return 1
}

apt_install_prerequisite() {
  local package="$1"

  if ! command -v apt-get >/dev/null 2>&1; then
    return 1
  fi

  echo "[run] Installing setup prerequisite: $package" >&2
  if [[ "$APT_UPDATED" != true ]]; then
    run_as_root apt-get update
    APT_UPDATED=true
  fi
  run_as_root apt-get install -y "$package"
}

verify_checksum() {
  local zip_path="$1"
  local sums_path="$2"
  local expected actual

  if [[ ! -f "$sums_path" ]]; then
    echo "Checksum file was not included in the release. Cannot verify bundle integrity." >&2
    return 1
  fi

  expected="$(awk '$2 == "workstation-bootstrap.zip" { print $1; exit }' "$sums_path")"
  if [[ -z "$expected" ]]; then
    echo "Checksum file does not include the setup bundle." >&2
    return 1
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$zip_path" | awk '{ print $1 }')"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$zip_path" | awk '{ print $1 }')"
  else
    echo "sha256sum or shasum is required." >&2
    return 1
  fi

  if [[ "$actual" != "$expected" ]]; then
    echo "Setup bundle verification failed." >&2
    return 1
  fi
}

extract_zip() {
  local zip_path="$1"
  local output_dir="$2"

  if command -v unzip >/dev/null 2>&1; then
    unzip -q "$zip_path" -d "$output_dir"
    return
  fi

  if apt_install_prerequisite unzip && command -v unzip >/dev/null 2>&1; then
    unzip -q "$zip_path" -d "$output_dir"
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$zip_path" "$output_dir" <<'PY'
import sys
import zipfile

zip_path, output_dir = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(zip_path) as archive:
    archive.extractall(output_dir)
PY
    return
  fi

  echo "unzip or python3 is required to extract the setup bundle." >&2
  if command -v apt-get >/dev/null 2>&1; then
    echo "Install one first, then run this setup again:" >&2
    echo "  sudo apt-get update && sudo apt-get install -y unzip" >&2
  fi
  return 1
}

detect_bootstrap() {
  case "$(uname -s)" in
    Darwin)
      printf '%s\n' "bootstrap/macos.sh"
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        printf '%s\n' "bootstrap/wsl.sh"
      else
        printf '%s\n' "bootstrap/linux.sh"
      fi
      ;;
    *)
      echo "Unsupported OS: $(uname -s)" >&2
      return 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      bootstrap_args+=("--apply")
      shift
      ;;
    --yes)
      bootstrap_args+=("--yes")
      shift
      ;;
    --version)
      WST_RELEASE="$2"
      shift 2
      ;;
    --version=*)
      WST_RELEASE="${1#*=}"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      bootstrap_args+=("$1")
      shift
      ;;
  esac
done

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

zip_path="$tmp_dir/workstation-bootstrap.zip"
sums_path="$tmp_dir/SHA256SUMS"
download_bundle "$zip_path" "$sums_path"
verify_checksum "$zip_path" "$sums_path"
extract_zip "$zip_path" "$tmp_dir"

bundle_root="$tmp_dir/workstation-bootstrap"
bootstrap_rel="$(detect_bootstrap)"
bootstrap_path="$bundle_root/$bootstrap_rel"

if [[ ! -f "$bootstrap_path" ]]; then
  echo "Setup file was not found in the downloaded bundle." >&2
  exit 1
fi

bootstrap_exit=0
if [[ -t 0 ]]; then
  bash "$bootstrap_path" "${bootstrap_args[@]}" || bootstrap_exit=$?
elif { : </dev/tty; } 2>/dev/null; then
  bash "$bootstrap_path" "${bootstrap_args[@]}" </dev/tty || bootstrap_exit=$?
else
  bash "$bootstrap_path" "${bootstrap_args[@]}" || bootstrap_exit=$?
fi

if [[ ! " ${bootstrap_args[*]} " =~ --apply ]]; then
  printf '\n'
  printf 'Next steps\n'
  printf '[next] bash %s --apply\n' "$0"
fi

exit "$bootstrap_exit"
