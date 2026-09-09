#!/usr/bin/env bash

set -euo pipefail

ACCOUNTS_ROOT="${HOME}/.codex-accounts"
ZSHRC_FILE="${HOME}/.zshrc"
BLOCK_START="# >>> codex multi-account setup >>>"
BLOCK_END="# <<< codex multi-account setup <<<"

die() {
  printf 'Fehler: %s\n' "$*" >&2
  exit 1
}

if [[ -z "${HOME:-}" ]]; then
  die 'HOME ist nicht gesetzt.'
fi

if ! command -v codex >/dev/null 2>&1; then
  die 'Die Codex CLI wurde nicht gefunden. Bitte installiere sie zuerst und starte dieses Skript anschließend erneut.'
fi

printf 'Codex Multi-Account-Einrichtung\n\n'

while true; do
  read -r -p 'Wie viele Accounts möchtest du anlegen? ' ACCOUNT_COUNT
  if [[ "$ACCOUNT_COUNT" =~ ^[1-9][0-9]*$ ]]; then
    break
  fi
  printf 'Bitte gib eine positive ganze Zahl ein.\n'
done

declare -a ACCOUNT_NAMES=()

for ((index = 1; index <= ACCOUNT_COUNT; index++)); do
  while true; do
    read -r -p "Name für Account ${index}: " ACCOUNT_NAME

    if [[ ! "$ACCOUNT_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
      printf 'Erlaubt sind Buchstaben, Zahlen, Unterstrich und Bindestrich; der Name muss mit Buchstabe oder Zahl beginnen.\n'
      continue
    fi

    DUPLICATE=false
    for EXISTING_NAME in "${ACCOUNT_NAMES[@]:-}"; do
      if [[ "$EXISTING_NAME" == "$ACCOUNT_NAME" ]]; then
        DUPLICATE=true
        break
      fi
    done

    if [[ "$DUPLICATE" == true ]]; then
      printf 'Dieser Accountname wurde bereits eingegeben.\n'
      continue
    fi

    ACCOUNT_NAMES+=("$ACCOUNT_NAME")
    break
  done
done

mkdir -p "$ACCOUNTS_ROOT"

ensure_file_credential_store() {
  local config_file="$1"
  local temp_file
  temp_file="$(mktemp "${TMPDIR:-/tmp}/codex-config.XXXXXX")"

  if [[ -f "$config_file" ]]; then
    awk '
      BEGIN { written = 0 }
      /^[[:space:]]*cli_auth_credentials_store[[:space:]]*=/ {
        if (!written) {
          print "cli_auth_credentials_store = \"file\""
          written = 1
        }
        next
      }
      { print }
      END {
        if (!written) {
          print "cli_auth_credentials_store = \"file\""
        }
      }
    ' "$config_file" > "$temp_file"
  else
    printf 'cli_auth_credentials_store = "file"\n' > "$temp_file"
  fi

  mv "$temp_file" "$config_file"
  chmod 600 "$config_file"
}

for ACCOUNT_NAME in "${ACCOUNT_NAMES[@]}"; do
  ACCOUNT_DIR="${ACCOUNTS_ROOT}/${ACCOUNT_NAME}"
  mkdir -p "$ACCOUNT_DIR"
  chmod 700 "$ACCOUNT_DIR"
  ensure_file_credential_store "${ACCOUNT_DIR}/config.toml"
done

touch "$ZSHRC_FILE"
ZSHRC_BACKUP="${ZSHRC_FILE}.codex-backup.$(date +%Y%m%d-%H%M%S)"
cp -p "$ZSHRC_FILE" "$ZSHRC_BACKUP"

ZSHRC_TEMP="$(mktemp "${TMPDIR:-/tmp}/codex-zshrc.XXXXXX")"
awk -v start="$BLOCK_START" -v end="$BLOCK_END" '
  $0 == start { inside = 1; next }
  $0 == end   { inside = 0; next }
  !inside     { print }
' "$ZSHRC_FILE" > "$ZSHRC_TEMP"

ACCOUNT_PATTERN=''
for ACCOUNT_NAME in "${ACCOUNT_NAMES[@]}"; do
  if [[ -n "$ACCOUNT_PATTERN" ]]; then
    ACCOUNT_PATTERN+='|'
  fi
  ACCOUNT_PATTERN+="$ACCOUNT_NAME"
done

{
  printf '\n%s\n' "$BLOCK_START"
  printf 'codex() {\n'
  printf '  case "${1:-}" in\n'
  printf '    %s)\n' "$ACCOUNT_PATTERN"
  printf '      local codex_account="$1"\n'
  printf '      shift\n'
  printf '      local codex_account_dir="$HOME/.codex-accounts/$codex_account"\n'
  printf '      mkdir -p "$codex_account_dir"\n'
  printf '      CODEX_HOME="$codex_account_dir" command codex "$@"\n'
  printf '      ;;\n'
  printf '    *)\n'
  printf '      command codex "$@"\n'
  printf '      ;;\n'
  printf '  esac\n'
  printf '}\n'
  printf '%s\n' "$BLOCK_END"
} >> "$ZSHRC_TEMP"

mv "$ZSHRC_TEMP" "$ZSHRC_FILE"

printf '\nEinrichtung abgeschlossen.\n'
printf 'Sicherung der bisherigen .zshrc: %s\n' "$ZSHRC_BACKUP"
printf '\nAktiviere die Änderung im aktuellen Terminal mit:\n'
printf 'source ~/.zshrc\n\n'

for ACCOUNT_NAME in "${ACCOUNT_NAMES[@]}"; do
  printf 'Login: codex %s login\n' "$ACCOUNT_NAME"
done

