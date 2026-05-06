#!/usr/bin/env bash
set -euo pipefail

DEFAULT_BUNDLE_URL="https://github.com/code-lift/workstation-bootstrap/releases/latest/download/workstation-bootstrap.zip"
DEFAULT_SHA256_URL="https://github.com/code-lift/workstation-bootstrap/releases/latest/download/SHA256SUMS"
BUNDLE_URL="${WORKSTATION_BUNDLE_URL:-$DEFAULT_BUNDLE_URL}"
SHA256_URL="${WORKSTATION_SHA256_URL:-}"
bootstrap_args=()

usage() {
  cat <<'USAGE'
Usage:
  install.sh [--apply] [--yes] [setup options...] [--help]

Public usage:
  curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply

Default:
  Preview mode. Downloads the setup bundle and shows what will happen without changing this computer.

Options:
  --apply                 Apply the selected setup.
  --yes                   Pass through automation confirmation.
  --help                  Show this help.

Environment:
  WORKSTATION_BUNDLE_URL  Override the setup bundle zip URL.
  WORKSTATION_SHA256_URL  Override the SHA256SUMS URL.

USAGE
}

download_file() {
  local url="$1"
  local output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fL "$url" -o "$output"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O "$output" "$url"
    return
  fi

  echo "curl or wget is required." >&2
  return 1
}

resolve_sha256_url() {
  if [[ -n "$SHA256_URL" ]]; then
    printf '%s\n' "$SHA256_URL"
    return
  fi

  if [[ "$BUNDLE_URL" == "$DEFAULT_BUNDLE_URL" ]]; then
    printf '%s\n' "$DEFAULT_SHA256_URL"
    return
  fi

  if [[ "$BUNDLE_URL" == file://* ]]; then
    local local_path="${BUNDLE_URL#file://}"
    local local_sums
    local_sums="$(dirname "$local_path")/SHA256SUMS"
    if [[ -f "$local_sums" ]]; then
      printf '%s\n' "file://$local_sums"
    fi
    return
  fi

  local sibling_url
  sibling_url="$(dirname "$BUNDLE_URL")/SHA256SUMS"
  printf '%s\n' "$sibling_url"
}

verify_checksum() {
  local zip_path="$1"
  local sums_url="$2"
  local sums_path="$3"
  local expected
  local actual

  if [[ -z "$sums_url" ]]; then
    echo "[warn] Checksum file is not configured. Skipping download verification." >&2
    return
  fi

  if ! download_file "$sums_url" "$sums_path"; then
    if [[ "$BUNDLE_URL" == "$DEFAULT_BUNDLE_URL" || -n "${WORKSTATION_SHA256_URL:-}" ]]; then
      echo "Failed to download checksum file." >&2
      return 1
    fi
    echo "[warn] Failed to download checksum file. Skipping verification for custom bundle." >&2
    return
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

if ! command -v unzip >/dev/null 2>&1; then
  echo "unzip is required." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

zip_path="$tmp_dir/workstation-bootstrap.zip"
sums_path="$tmp_dir/SHA256SUMS"
download_file "$BUNDLE_URL" "$zip_path"
verify_checksum "$zip_path" "$(resolve_sha256_url)" "$sums_path"
unzip -q "$zip_path" -d "$tmp_dir"

bundle_root="$tmp_dir/workstation-bootstrap"
bootstrap_rel="$(detect_bootstrap)"
bootstrap_path="$bundle_root/$bootstrap_rel"

if [[ ! -f "$bootstrap_path" ]]; then
  echo "Setup file was not found in the downloaded bundle." >&2
  exit 1
fi

if [[ -t 0 ]]; then
  bash "$bootstrap_path" "${bootstrap_args[@]}"
elif { : </dev/tty; } 2>/dev/null; then
  bash "$bootstrap_path" "${bootstrap_args[@]}" </dev/tty
else
  bash "$bootstrap_path" "${bootstrap_args[@]}"
fi
