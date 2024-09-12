#!/bin/bash

# "Makefile-like" script for deploying this mod

# Ideas:
# Configure tar (backup) command-line arguments
# Configure cp command-line arguments and/or behavior

SELF="$(dirname "$0")"
MOD_NAME="$(basename "$(readlink -f "$SELF")")"

print_usage() {
  cat <<EOF >&2
usage: $0 [-h] [-v|-V] [-n] [-b DIR] [-C] [-F] [-N DIR] [-a ARG] [-i PATH]
          [-x PAT] [ACTION]

actions:
    diff    compare local and deployed versions of this mod (default)
    diffw   compare local and workshop versions of this mod
    diffd   compare deployed and workshop versions of this mod
    cp      copy this mod to the Noita mods directory

options:
    -h      print this message and exit
    -v      enable verbose diagnostics
    -V      enable verbose diagnostics and set -x
    -n      dry run; don't actually do anything
    -l PATH path to luacheck.sh script
    -L ARG  pass ARG to luacheck command line
    -b DIR  backup destination into DIR/ before overwriting
    -C      disable color formatting
    -F      copy items even if there are no detected differences
    -N DIR  specify path to Noita game directory
    -a ARG  prepend ARG to the diff command-line
    -i PATH include PATH in the objects to copy over
    -x PAT  exclude files matching PAT

environment variables:
    NOITA   path to Noita game directory
    STEAM   path to steam root directory (used if NOITA isn't defined)
EOF
}

declare -a LUACHECK_ARGS=()
NOITA_PATH="${NOITA:-}"
declare -a DIFF_ARGS=()
declare -a COPY_EXTRA=()
declare -a EXCLUDE_EXTRA=('*.sh' .luacheckrc)

while getopts "hvVnl:L:b:CFN:a:i:x:" arg; do
  case "$arg" in
    h) print_usage; exit 0;;
    v) DEBUG=1;;
    V) DEBUG=1; set -x;;
    b) BACKUP="$OPTARG";;
    n) DRY_RUN=1;;
    l) LUACHECK="$OPTARG";;
    L) LUACHECK_ARGS+=("$OPTARG");;
    C) NOCOLOR=1;;
    F) FORCE_COPY=1;;
    N) NOITA_PATH="$OPTARG";;
    a) DIFF_ARGS+=("$OPTARG");;
    i) COPY_EXTRA+=("$OPTARG");;
    x) EXCLUDE_EXTRA+=("$OPTARG");;
  esac
done
shift $((OPTIND - 1))

# Allow for ../luacheck.sh as a default
if [[ -z "${LUACHECK:-}" ]]; then
  if [[ -x "$SELF/../luacheck.sh" ]]; then
    LUACHECK="$SELF/../luacheck.sh"
  fi
fi

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
  diff_args+=(-x "$(basename "$0")")  # because this script isn't required
  diff_args+=(-x "*.tar.gz")          # because backups
  diff_args+=(-x "ref")               # remove reference items
  diff_args+=(-x "build")             # remove compilation/bundling stuff
  diff_args+=(-x .gitignore)          # remove gitignore
  diff_args+=(-x README.md)           # remove readme
  diff_args+=(-x '*.sh')              # Noita doesn't like shell scripts
  diff_args+=(-x workshop_id.txt -x workshop.xml -x workshop_preview_image.png)

  for line in $(git ls-files --directory -o -x '*.swp' | sed -e 's/\/$//'); do
    debug "Excluding untracked file $line"
    diff_args+=(-x "$line")
  done

  for pat in "${EXCLUDE_EXTRA[@]}"; do
    diff_args+=(-x "$pat")
  done

  if [[ -z "${DEBUG:-}" ]]; then
    diff_args+=("-q")
  else
    declare -p diff_args
  fi

  if [[ -d "$2" ]]; then
    debug "diff ${diff_args[@]} -r -x .* '$1' '$2'"
    diff "${diff_args[@]}" -r -x '.*' "$1" "$2"
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

# Get the workshop base directory
get_workshop_base() {
  local noita_dir="$(find_noita)"
  if [[ $? -ne 0 ]]; then
    return 1
  fi
  readlink -f "$noita_dir/../../workshop/content/881100"
}

get_workshop_path() { # mod-path
  if [[ ! -f "$1/workshop_id.txt" ]]; then
    error "$1 missing workshop_id.txt"
    return 1
  fi
  local workshop_base="$(get_workshop_base)"
  if [[ $? -ne 0 ]]; then
    error "Failed to find workshop base directory"
    return 1
  fi
  local workshop_id="$(cat "$1/workshop_id.txt")"
  local mod_path="$workshop_base/$workshop_id"
  debug "mod_path=$mod_path"
  if [[ ! -d "$mod_path" ]]; then
    error "$1 (ID $workshop_id) not installed via workshop"
    return 1
  fi
  echo "$mod_path"
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

# Check if we should skip deploying the given object; 0 = skip, 1 = include
deploy_check_skip() { # path
  if [[ "$1" == build ]]; then return 0; fi
  if [[ "$1" =~ build/.* ]]; then return 0; fi
  if git check-ignore -q "$1"; then return 0; fi
  for pat in "${EXCLUDE_EXTRA[@]}"; do
    local result="$(find "$1" -maxdepth 0 -name "$pat" -print)"
    if [[ -n "$result" ]]; then
      debug "deploy_check_skip $1 due to $pat"
      return 0
    fi
  done
  return 1
}

# Copy a single item in the current repo to the dest directory
deploy_one() { # entry dest
  local entry="$1"
  local dest="$2"
  local dpath="$(dirname "$entry")"
  info "Replicating $entry to $dest/$entry"
  if [[ "$entry" =~ \.lua$ ]]; then
    do_luacheck "$entry"
  fi
  if [[ -n "$dpath" ]] && [[ "$dpath" != "." ]]; then
    if [[ ! -d "$dest/$dpath" ]]; then
      dry checked mkdir -p "$dest/$dpath"
    fi
  fi
  if [[ ! -d "$entry" ]]; then
    dry checked cp "$entry" "$dest/$entry"
  elif [[ -e "$dest/$entry" ]]; then
    dry checked cp -r "$entry" "$dest/"
  else
    dry checked cp -r "$entry" "$dest/$entry"
  fi
}

# Copy the files in the current repo to the dest directory
deploy() { # dest
  local dest="$1"
  git ls-files -c | while read entry; do
    deploy_check_skip $entry && continue
    deploy_one "$entry" "$dest"
  done

  for entry in "${COPY_EXTRA[@]}"; do
    deploy_one "$entry" "$dest"
  done
}

# Invoke luacheck on the file
do_luacheck() { # file...
  if [[ -z "${LUACHECK:-}" ]]; then
    info "luacheck not available; skipping check"
  elif [[ -x "${LUACHECK:-}" ]]; then
    "$LUACHECK" "${LUACHECK_ARGS[@]}" "$@"
    return $?
  else
    warn "luacheck '$LUACHECK' not executable"
  fi
  return 0
}

NOITA="$(find_noita)"
if [[ $? -ne 0 ]]; then
  error "Aborting"
  exit 1
fi

DEST_DIR="$NOITA/mods/$MOD_NAME"

DIFF_LEFT="local"
DIFF_RIGHT="deployed"
DIFF_FROM="$SELF"
DIFF_TO="$DEST_DIR"
case "$ACTION" in
  cp) ;;
  diff) ;;
  diffw)
    DIFF_LEFT="workshop";
    DIFF_RIGHT="local";
    DIFF_FROM="$(get_workshop_path "$SELF")";
    DIFF_TO="$SELF";;
  diffd)
    DIFF_LEFT="workshop";
    DIFF_RIGHT="deployed";
    DIFF_FROM="$(get_workshop_path "$SELF")";
    DIFF_TO="$DEST_DIR";;
  *)
    error "Invalid action $ACTION";
    print_usage;
    exit 1;;
esac

debug "Comparing $DIFF_LEFT (as $DIFF_FROM) with $DIFF_RIGHT (as $DIFF_TO)"

compare_mods "$DIFF_FROM" "$DIFF_TO"
DIFF_STATUS=$?

if [[ $DIFF_STATUS -ne 0 ]]; then
  info "Detected differences between $DIFF_LEFT and $DIFF_RIGHT directories"
elif [[ -n "${FORCE_COPY:-}" ]] && [[ "$ACTION" != "cp" ]]; then
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

  # Deploy this mod to the destination directory
  info "Copying . to $DEST_DIR"
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
