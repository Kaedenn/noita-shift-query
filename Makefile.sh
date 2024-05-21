#!/bin/bash

# Trivial "Makefile-like" script for deploying this mod

# Ideas:
# Configure tar (backup) command-line arguments
# Configure cp command-line arguments and/or behavior

SELF="$(dirname "$0")"
MOD_NAME="$(basename "$(readlink -f "$SELF")")"

print_usage() {
  cat <<EOF >&2
usage: $0 [-h] [-v|-V] [-n] [-b DIR] [-C] [-F] [-N DIR] [-a ARG] [ACTION]

actions:
    diff    compare local and deployed versions of this mod (default)
    cp      copy this mod to the Noita mods directory

options:
    -h      print this message and exit
    -v      enable verbose diagnostics
    -V      enable verbose diagnostics and set -x
    -n      dry run; don't actually do anything
    -b DIR  backup destination into DIR/ before overwriting
    -C      disable color formatting
    -F      copy items even if there are no detected differences
    -N DIR  specify path to Noita game directory
    -a ARG  prepend ARG to the diff command-line

environment variables:
    NOITA   path to Noita game directory
    STEAM   path to steam root directory (used if NOITA isn't defined)
EOF
}

NOITA_PATH="${NOITA:-}"
declare -a DIFF_ARGS=()

while getopts "hvVnb:CFN:a:" arg; do
  case "$arg" in
    h) print_usage; exit 0;;
    v) DEBUG=1;;
    V) DEBUG=1; set -x;;
    b) BACKUP="$OPTARG";;
    n) DRY_RUN=1;;
    C) NOCOLOR=1;;
    F) FORCE_COPY=1;;
    N) NOITA_PATH="$OPTARG";;
    a) DIFF_ARGS+=("$OPTARG");;
  esac
done
shift $((OPTIND - 1))

ACTION="${1:-diff}"

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

diag() { # prefix message...
  echo -e "$1: ${@:2}" >&2
}

error() { diag "$(color 1 91 ERROR)" "$@"; }
info() { diag "$(color 1 94 INFO)" "$@"; }
warn() { diag "$(color 1 93 WARNING)" "$@"; }
debug() { if [[ -n "${DEBUG:-}" ]]; then diag "$(color 1 92 DEBUG)" "$@"; fi; }

get_branch() { git branch --show-current 2>/dev/null; }

dry() { # command...
  if [[ -z "${DRY_RUN:-}" ]]; then
    $@; return $?
  fi
  info "$(color 93 DRY): $@"
  return 0 # assume success
}

checked() { # command...
  local -a cmdargs=()
  for arg in "$@"; do
    local argq="$(printf '%q' "$arg")"
    if [[ "$argq" != "$arg" ]]; then
      cmdargs+=("'$arg'")
    else
      cmdargs+=("$arg")
    fi
  done
  debug "checked argv=${#cmdargs[@]} ${cmdargs[@]}"
  $@
  local status=$?
  if [[ $status -ne 0 ]]; then
    error "command ${cmdargs[0]} exited non-zero $status"
    exit 1
  fi
  return $status
}

# Compare two directories. Returns 1 on differences.
compare_mods() { # local remote
  local diff_args=(${DIFF_ARGS[@]})
  diff_args+=(-x "$(basename "$0")") # because this script isn't required
  diff_args+=(-x "*.tar.gz")         # because backups
  diff_args+=(-x "ref")              # remove reference items
  diff_args+=(-x "build")            # remove compilation/bundling stuff
  if [[ -z "${DEBUG:-}" ]]; then
    diff_args+=("-q")
  fi
  if [[ -d "$2" ]]; then
    debug "diff ${diff_args[@]} -r -x '.*' '$1' '$2'"
    diff ${diff_args[@]} -r -x '.*' "$1" "$2"
    return $?
  fi
  return 1
}

# Locate the Steam root directory
find_steam() {
  if [[ -n "${STEAM:-}" ]]; then
    echo "$STEAM"
    return 0
  fi

  if [[ -d "$HOME/.steam" ]]; then
    for link in steam root; do
      local slink="$HOME/.steam/$link"
      if [[ -h "$slink" && -d "$slink" ]]; then
        echo "$(readlink -f "$slink")"
        return 0
      fi
    done
  fi

  return 1
}

# True if the given path is a Noita installation directory
is_noita_dir() { # path
  test -f "$1/noita.exe"
  return $?
}

# Locate the Noita game directory (the directory containing noita.exe)
find_noita() {
  local noita_path="${NOITA_PATH:-}"
  if [[ -z "$noita_path" ]]; then
    local steam_root="$(find_steam)"
    if [[ $? -ne 0 ]]; then
      error "Failed to find Steam root directory"
      error "Please specify '-m path/to/Noita'"
      return 1
    fi

    for sapps in SteamApps steamapps; do # this changed sometime after Ubuntu 12
      if is_noita_dir "$steam_root/$sapps/common/Noita"; then
        noita_path="$steam_root/$sapps/common/Noita"
      fi
    done
  fi

  if [[ -z "$noita_path" ]]; then
    error "failed to locate Noita; please specify '-m path/to/Noita'"
  elif ! is_noita_dir "$noita_path"; then
    error "$noita_path does not contain noita.exe; is this the correct path?"
  else
    echo "$noita_path"
    return 0
  fi
  return 1
}

# Archive the given path
archive_path() { # archive-name path
  local tar_file="$(readlink -f "$1")"
  if [[ -z "$tar_file" ]]; then
    error "failed to resolve $1"
    return 1
  fi

  local -a tar_args=()
  if [[ -n "${DEBUG:-}" ]]; then
    tar_args+=(cvfz)
  else
    tar_args+=(cfz)
  fi
  tar_args+=("$tar_file")
  tar_args+=(-C "$2/..")
  tar_args+=(--exclude .git)
  tar_args+=(--exclude '*.swp')

  checked tar ${tar_args[@]} "$(basename "$2")"
}

# Check if this archive is unique among the others in the directory
archive_is_unique() { # path file
  local file_hash="$(md5sum "$2" | awk '{ print $1 }')"
  local file_name="$(basename "$2")"
  for file in "$1"/*; do
    if [[ -d "$file" ]]; then continue; fi
    local test_name="$(basename "$file")"
    if [[ "$test_name" != "$file_name" ]]; then
      local test_hash="$(md5sum "$file" | awk '{ print $1 }')"
      if [[ "$test_hash" == "$file_hash" ]]; then
        warn "Archive $2 duplicates $file"
        return 1
      fi
    fi
  done
  return 0
}

# Check if we should skip deploying the given object
deploy_check_skip() { # path
  if [[ $1 == build ]]; then return 0; fi
  if [[ $1 =~ build/.* ]]; then return 0; fi
  return 1
}

# Copy the files in the current repo to the dest directory
deploy() { # dest
  local dest="$1"
  git ls-tree -r --name-only $(git branch --show-current) | while read entry; do
    deploy_check_skip $entry && continue
    local dpath="$(dirname "$entry")"
    info "Replicating $entry to $dest/$entry"
    if [[ -n "$dpath" ]] && [[ "$dpath" != "." ]]; then
      if [[ ! -d "$dest/$dpath" ]]; then
        dry checked mkdir -p "$dest/$dpath"
      fi
    fi
    dry checked cp "$entry" "$dest/$entry"
  done
}

NOITA="$(find_noita)"
if [[ $? -ne 0 ]]; then
  error "Aborting"
  exit 1
fi

DEST_DIR="$NOITA/mods/$MOD_NAME"
debug "Comparing . (as $MOD_NAME) with $DEST_DIR"

compare_mods "$SELF" "$DEST_DIR"
DIFF_STATUS=$?

if [[ $DIFF_STATUS -ne 0 ]]; then
  info "Detected differences between local and deployed directories"
elif [[ -n "${FORCE_COPY:-}" ]]; then
  info "No differences detected, but copying anyway"
else
  info "No differences detected"
  exit 0
fi

if [[ "$ACTION" == "cp" ]]; then

  # Should we create a backup of the deployed directory?
  if [[ -n "${BACKUP:-}" ]]; then
    BKFILE="$BACKUP/$MOD_NAME-$(date +%Y%m%d-%H%M%S).tar.gz"
    checked archive_path "$BKFILE" "$DEST_DIR"
    info "Backed-up $DEST_DIR to $BKFILE"
    if ! archive_is_unique "$BACKUP" "$BKFILE"; then
      warn "$BKFILE duplicates a previous backup file; removing"
      checked rm "$BKFILE"
    fi
  fi

  info "Copying . to $DEST_DIR"
  # Deploy this mod to the destination directory
  if [[ -d "$DEST_DIR" ]]; then
    dry checked rm -r "$DEST_DIR"
  fi
  if [[ $? -eq 0 ]]; then
    mkdir "$DEST_DIR" 2>/dev/null
    if checked deploy "$DEST_DIR"; then
      info "Done"
    fi
  fi

else
  info "Execute '$0 [ARGS...] cp' to deploy $MOD_NAME"
fi

# vim: set ts=2 sts=2 sw=2:
