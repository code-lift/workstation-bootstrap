#!/usr/bin/env bash
set -euo pipefail

DEFAULT_BUNDLE_URL="https://github.com/code-lift/workstation-bootstrap/releases/latest/download/workstation-bootstrap.zip"
DEFAULT_SHA256_URL="https://github.com/code-lift/workstation-bootstrap/releases/latest/download/SHA256SUMS"
BUNDLE_URL="${WORKSTATION_BUNDLE_URL:-$DEFAULT_BUNDLE_URL}"
SHA256_URL="${WORKSTATION_SHA256_URL:-}"
bootstrap_args=()
APT_UPDATED=false

usage() {
  cat <<'USAGE'
Usage:
  install.sh [--apply] [--yes] [setup options...] [--help]

Public usage:
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh)"
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh)" -- --apply

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

ensure_downloader() {
  if command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; then
    return
  fi

  if apt_install_prerequisite curl; then
    return
  fi

  echo "curl or wget is required to download the setup bundle." >&2
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
ensure_downloader
download_file "$BUNDLE_URL" "$zip_path"
verify_checksum "$zip_path" "$(resolve_sha256_url)" "$sums_path"
extract_zip "$zip_path" "$tmp_dir"

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
