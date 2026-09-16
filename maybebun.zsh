# maybeBun
# You typed npm. Maybe Bun?
#
# Source this file from ~/.zshrc.
# Do not execute this file directly.

# Prevent duplicate loading
if [[ -n "${MAYBEBUN_LOADED:-}" ]]; then
  return 0
fi

MAYBEBUN_LOADED=1


# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

_maybebun_check() {
  if ! command -v bun >/dev/null 2>&1; then
    echo "maybeBun: Bun is not installed."
    return 1
  fi

  if ! command -v gum >/dev/null 2>&1; then
    echo "maybeBun: gum is not installed."
    echo "Install it with: brew install gum"
    return 1
  fi

  return 0
}


_maybebun_display() {
  local result=""
  local arg

  for arg in "$@"; do
    if [[ -z "$result" ]]; then
      result="${(q)arg}"
    else
      result="$result ${(q)arg}"
    fi
  done

  print -r -- "$result"
}


_maybebun_choose() {
  local label="$1"
  shift

  local original_display="$1"
  shift

  local bun_display="$1"
  shift

  echo

  local choice

  choice=$(
    printf 'Bun\t%s\n%s\t%s\n' \
      "$bun_display" \
      "$label" \
      "$original_display" |
      gum choose \
        --header "Run with" \
        --footer "↑↓ move  •  enter select  •  esc cancel" \
        --cursor "❯ " \
        --cursor-prefix "  " \
        --selected-prefix "❯ " \
        --unselected-prefix "  "
  )

  local status=$?

  if (( status != 0 )) || [[ -z "$choice" ]]; then
    echo
    return 130
  fi

  echo

  if [[ "$choice" == Bun$'\t'* ]]; then
    eval "$bun_display"
  else
    eval "$original_display"
  fi
}


# ─────────────────────────────────────────────
# npm
# ─────────────────────────────────────────────

npm() {
  # No arguments → normal npm
  if (( $# == 0 )); then
    command npm
    return $?
  fi

  local original_display
  local bun_display=""
  local args=""
  local arg

  original_display="$(_maybebun_display npm "$@")"

  case "$1" in

    install|i)

      # npm install
      if (( $# == 1 )); then
        bun_display="bun install"

      # npm install -g foo
      elif [[ "$2" == "-g" || "$2" == "--global" ]]; then
        args="$(_maybebun_display "${@[3,-1]}")"
        bun_display="bun add -g $args"

      # npm install -D foo
      elif [[ "$2" == "-D" || "$2" == "--save-dev" ]]; then
        args="$(_maybebun_display "${@[3,-1]}")"
        bun_display="bun add -d $args"

      # npm install -O foo
      elif [[ "$2" == "-O" || "$2" == "--save-optional" ]]; then
        args="$(_maybebun_display "${@[3,-1]}")"
        bun_display="bun add --optional $args"

      # npm install foo
      else
        local -a converted
        converted=()

        for arg in "${@[2,-1]}"; do
          case "$arg" in
            --save-dev)
              converted+=("-d")
              ;;

            --global)
              converted+=("-g")
              ;;

            --save-optional)
              converted+=("--optional")
              ;;

            --save)
              ;;

            *)
              converted+=("$arg")
              ;;
          esac
        done

        args="$(_maybebun_display "${converted[@]}")"
        bun_display="bun add $args"
      fi
      ;;


    uninstall|remove|rm|un)
      args="$(_maybebun_display "${@[2,-1]}")"
      bun_display="bun remove $args"
      ;;


    ci)
      bun_display="bun install --frozen-lockfile"
      ;;


    run|run-script)
      if (( $# < 2 )); then
        command npm "$@"
        return $?
      fi

      args="$(_maybebun_display "${@[2,-1]}")"
      bun_display="bun run $args"
      ;;


    exec|x)
      if (( $# < 2 )); then
        command npm "$@"
        return $?
      fi

      args="$(_maybebun_display "${@[2,-1]}")"
      bun_display="bunx $args"
      ;;


    test|t)
      if (( $# > 1 )); then
        args="$(_maybebun_display "${@[2,-1]}")"
        bun_display="bun test $args"
      else
        bun_display="bun test"
      fi
      ;;


    start)
      if (( $# > 1 )); then
        args="$(_maybebun_display "${@[2,-1]}")"
        bun_display="bun run start $args"
      else
        bun_display="bun run start"
      fi
      ;;


    create)
      if (( $# < 2 )); then
        command npm "$@"
        return $?
      fi

      args="$(_maybebun_display "${@[2,-1]}")"
      bun_display="bun create $args"
      ;;


    init)
      if (( $# == 1 )); then
        bun_display="bun init"

      elif [[ "$2" == "-y" || "$2" == "--yes" ]]; then
        bun_display="bun init -y"

      else
        command npm "$@"
        return $?
      fi
      ;;


    link)
      if (( $# > 1 )); then
        args="$(_maybebun_display "${@[2,-1]}")"
        bun_display="bun link $args"
      else
        bun_display="bun link"
      fi
      ;;


    unlink)
      if (( $# > 1 )); then
        args="$(_maybebun_display "${@[2,-1]}")"
        bun_display="bun unlink $args"
      else
        bun_display="bun unlink"
      fi
      ;;


    update|up)
      if (( $# > 1 )); then
        args="$(_maybebun_display "${@[2,-1]}")"
        bun_display="bun update $args"
      else
        bun_display="bun update"
      fi
      ;;


    outdated)
      if (( $# > 1 )); then
        args="$(_maybebun_display "${@[2,-1]}")"
        bun_display="bun outdated $args"
      else
        bun_display="bun outdated"
      fi
      ;;


    # No safe/obvious Bun equivalent.
    # Run npm normally.
    *)
      command npm "$@"
      return $?
      ;;

  esac

  if ! _maybebun_check; then
    return 1
  fi

  _maybebun_choose \
    "npm" \
    "$original_display" \
    "$bun_display"
}


# ─────────────────────────────────────────────
# npx
# ─────────────────────────────────────────────

npx() {
  if (( $# == 0 )); then
    command npx
    return $?
  fi

  if ! _maybebun_check; then
    return 1
  fi

  local original_display
  local bun_display
  local args

  original_display="$(_maybebun_display npx "$@")"
  args="$(_maybebun_display "$@")"
  bun_display="bunx $args"

  _maybebun_choose \
    "npx" \
    "$original_display" \
    "$bun_display"
}
