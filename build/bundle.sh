#!/bin/bash

# Bundle this mod for sharing

BUILD="$(dirname "$0")"
BASE="$BUILD/.."

# Default color codes
cE_D='1 91'
cI_D='1 94'
cW_D='1 93'
cD_D='1 92'

NOCOLOR=${NOCOLOR:-}
OFILE=
DIRNAME="shift_query"
VERSION="latest"

print_usage() {
  cat <<EOF >&2
usage: $0 [-h] [-v] [-o FILE]

options:
    -h      print this message and exit
    -v      enable verbose diagnostics
    -C      disable color formatting
    -o FILE write to FILE instead of \$BUILD/shift_query/\$VERSION.zip
    -O NAME overwrite the mod directory name
    -V VER  tag the archive with the given version; default $VERSION

environment variables:
    cE      error color codes; default $cE_D
    cI      info color codes; default $cI_D
    cW      warning color codes; default $cW_D
    cD      debug color codes; default $cD_D

This script generates \$BUILD/shift_query_\$VERSION.zip from the files
in $BASE. The resulting archive can then be extracted directly into the
Noita mods folder.

EOF
}

ifunset() { # var default
  if ! declare -p "$1" >/dev/null 2>&1; then
    declare -n ref="$1"
    echo "$ref"
  else
    echo "$2"
  fi
}

while getopts "hvCo:O:V:" arg; do
  case "$arg" in
    h) print_usage; exit 0;;
    v) DEBUG=1;;
    C) NOCOLOR=1;;
    o) OFILE="$OPTARG";;
    O) DIRNAME="$OPTARG";;
    V) VERSION="$OPTARG";;
  esac
done
shift $((OPTIND - 1))

if [[ -z "$OFILE" ]]; then
  OFILE="$BUILD/shift_query-${VERSION}.zip"
fi

# Color codes

export cE="$(ifunset cE "$cE_D")"
export cI="$(ifunset cI "$cI_D")"
export cW="$(ifunset cW "$cW_D")"
export cD="$(ifunset cD "$cD_D")"

color() { # code message...
  let ncodes=$#-1
  local IFS=';'
  local code=${*:1:$ncodes}
  local msg="${@:$#}"
  if [[ -z "${NOCOLOR:-}" ]]; then
    echo -e "\033[${code}m${msg}\033[0m"
  else
    echo "${msg}"
  fi
}

diag() { echo -e "$1: ${@:2}" >&2; }

error() { diag "$(color $cE ERROR)" "$@"; }
info() { diag "$(color $cI INFO)" "$@"; }
warn() { diag "$(color $cW WARNING)" "$@"; }
debug() { if [[ -n "${DEBUG:-}" ]]; then diag "$(color $cD DEBUG)" "$@"; fi; }

if [[ -f "$OFILE" ]]; then
  warn "$OFILE exists; overwriting..."
fi

if [[ -d "$BUILD/$DIRNAME" ]]; then
  warn "$BUILD/$DIRNAME exists; purging..."
  rm -r "$BUILD/$DIRNAME" || exit $?
fi

debug "Bundling mod to $OFILE..."

mkdir "$BUILD/$DIRNAME" || exit $?
find "$BASE" -type f \! -wholename '*.git/*' \! -name '.*' -exec cp "{}" "$BUILD/$DIRNAME" \; || exit $?

zip -r "$OFILE" "$BUILD/$DIRNAME"

rm -r "$BUILD/$DIRNAME" || exit $?
