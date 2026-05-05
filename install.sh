#!/usr/bin/env bash
set -euo pipefail

DEFAULT_BUNDLE_URL="https://github.com/code-lift/workstation-bootstrap/releases/latest/download/workstation-bootstrap.zip"
DEFAULT_SHA256_URL="https://github.com/code-lift/workstation-bootstrap/releases/latest/download/SHA256SUMS"
BUNDLE_URL="${WORKSTATION_BUNDLE_URL:-$DEFAULT_BUNDLE_URL}"
SHA256_URL="${WORKSTATION_SHA256_URL:-}"
apply=false
bootstrap_args=()

usage() {
  cat <<'USAGE'
Usage:
  install.sh [--apply] [bootstrap options...] [--help]

Public usage:
  curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash
  curl -fsSL https://raw.githubusercontent.com/code-lift/workstation-bootstrap/main/install.sh | bash -s -- --apply

Default:
  Dry-run. Downloads the public bootstrap bundle and runs the OS bootstrap without making changes.

Options:
  --apply                 Apply changes.
  --help                  Show this help.

Environment:
  WORKSTATION_BUNDLE_URL  Override the bootstrap bundle zip URL.
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

  echo "curl 또는 wget이 필요하다." >&2
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
    echo "[warn] SHA256SUMS URL 없음. checksum 검증을 건너뛴다." >&2
    return
  fi

  if ! download_file "$sums_url" "$sums_path"; then
    if [[ "$BUNDLE_URL" == "$DEFAULT_BUNDLE_URL" || -n "${WORKSTATION_SHA256_URL:-}" ]]; then
      echo "SHA256SUMS 다운로드 실패: $sums_url" >&2
      return 1
    fi
    echo "[warn] SHA256SUMS 다운로드 실패. custom bundle checksum 검증을 건너뛴다: $sums_url" >&2
    return
  fi

  expected="$(awk '$2 == "workstation-bootstrap.zip" { print $1; exit }' "$sums_path")"
  if [[ -z "$expected" ]]; then
    echo "SHA256SUMS에 workstation-bootstrap.zip 항목이 없다." >&2
    return 1
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$zip_path" | awk '{ print $1 }')"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$zip_path" | awk '{ print $1 }')"
  else
    echo "sha256sum 또는 shasum이 필요하다." >&2
    return 1
  fi

  if [[ "$actual" != "$expected" ]]; then
    echo "checksum 불일치: workstation-bootstrap.zip" >&2
    echo "expected: $expected" >&2
    echo "actual:   $actual" >&2
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
      echo "지원하지 않는 OS: $(uname -s)" >&2
      return 1
      ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      apply=true
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
  echo "unzip이 필요하다." >&2
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
  echo "bootstrap 파일 없음: $bootstrap_rel" >&2
  exit 1
fi

if "$apply"; then
  echo "mode: apply"
else
  echo "mode: dry-run"
fi

bash "$bootstrap_path" "${bootstrap_args[@]}"
