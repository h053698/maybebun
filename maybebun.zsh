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


# Render an argv array as a human-readable command line.
# Display only — never fed back to the shell for execution.
_maybebun_display() {
  local -a _mb_words
  _mb_words=("${(@P)1}")

  print -r -- "${(j: :)${(q-)_mb_words[@]}}"
}


# Show the picker and run the chosen command.
#
# Both commands are passed by *array name*, so they are executed as
# argv arrays via "$cmd[@]" rather than being re-parsed by eval.
_maybebun_choose() {
  local label="$1"
  local original_name="$2"
  local bun_name="$3"

  # Deliberately odd local names: ${(@P)} resolves in this scope, so a local
  # sharing the caller's variable name would shadow it and expand to nothing.
  local -a _mb_orig _mb_bun
  _mb_orig=("${(@P)original_name}")
  _mb_bun=("${(@P)bun_name}")

  # Non-interactive (script, pipe, subshell): no prompt is possible.
  # Run the command the user actually typed.
  if [[ ! -t 0 || ! -t 2 ]]; then
    command "${_mb_orig[@]}"
    return $?
  fi

  local original_display bun_display
  original_display="$(_maybebun_display _mb_orig)"
  bun_display="$(_maybebun_display _mb_bun)"

  echo

  local choice exit_code

  choice=$(
    printf '%-*s  %s\n' \
      3 "Bun" "$bun_display" \
      3 "$label" "$original_display" |
      gum choose \
        --header "Run with" \
        --cursor "❯ " \
        --cursor-prefix "  " \
        --selected-prefix "❯ " \
        --unselected-prefix "  "
  )

  exit_code=$?

  # Esc / Ctrl-C / no selection → run nothing.
  if (( exit_code != 0 )) || [[ -z "$choice" ]]; then
    echo
    return 130
  fi

  echo

  if [[ "$choice" == "Bun"* ]]; then
    command "${_mb_bun[@]}"
  else
    # `command` bypasses this wrapper function, so npm/npx runs for real
    # instead of recursing back into maybeBun.
    command "${_mb_orig[@]}"
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

  local -a original_cmd bun_cmd rest
  local arg

  original_cmd=(npm "$@")
  bun_cmd=()
  rest=("${@[2,-1]}")

  case "$1" in

    install|i|add)

      # npm install
      if (( $# == 1 )); then
        bun_cmd=(bun install)

      # npm install <args...>
      else
        local -a converted
        converted=()

        for arg in "${rest[@]}"; do
          case "$arg" in
            -D|--save-dev)
              converted+=(--dev)
              ;;

            -O|--save-optional)
              converted+=(--optional)
              ;;

            -E|--save-exact)
              converted+=(--exact)
              ;;

            -g|--global)
              converted+=(--global)
              ;;

            # Default in both npm and Bun. Nothing to translate.
            -S|--save)
              ;;

            *)
              converted+=("$arg")
              ;;
          esac
        done

        bun_cmd=(bun add "${converted[@]}")
      fi
      ;;


    uninstall|remove|rm|un)
      if (( $# < 2 )); then
        command npm "$@"
        return $?
      fi

      bun_cmd=(bun remove "${rest[@]}")
      ;;


    ci)
      bun_cmd=(bun install --frozen-lockfile)
      ;;


    run|run-script)
      if (( $# < 2 )); then
        command npm "$@"
        return $?
      fi

      bun_cmd=(bun run "${rest[@]}")
      ;;


    exec|x)
      if (( $# < 2 )); then
        command npm "$@"
        return $?
      fi

      bun_cmd=(bunx "${rest[@]}")
      ;;


    # `npm test` runs the package.json "test" script, which is what
    # `bun run test` does. `bun test` is Bun's own test runner and would
    # ignore the script entirely.
    test|t|tst)
      bun_cmd=(bun run test "${rest[@]}")
      ;;


    start)
      bun_cmd=(bun run start "${rest[@]}")
      ;;


    create)
      if (( $# < 2 )); then
        command npm "$@"
        return $?
      fi

      bun_cmd=(bun create "${rest[@]}")
      ;;


    init)
      if (( $# == 1 )); then
        bun_cmd=(bun init)

      elif [[ "$2" == "-y" || "$2" == "--yes" ]]; then
        bun_cmd=(bun init -y)

      else
        command npm "$@"
        return $?
      fi
      ;;


    link)
      bun_cmd=(bun link "${rest[@]}")
      ;;


    unlink)
      bun_cmd=(bun unlink "${rest[@]}")
      ;;


    update|up|upgrade)
      bun_cmd=(bun update "${rest[@]}")
      ;;


    outdated)
      bun_cmd=(bun outdated "${rest[@]}")
      ;;


    publish)
      bun_cmd=(bun publish "${rest[@]}")
      ;;


    pack)
      bun_cmd=(bun pm pack "${rest[@]}")
      ;;


    # No safe/obvious Bun equivalent.
    # Run npm normally.
    *)
      command npm "$@"
      return $?
      ;;

  esac

  if ! _maybebun_check; then
    # Bun or gum missing → still honor what the user typed.
    command npm "$@"
    return $?
  fi

  _maybebun_choose "npm" original_cmd bun_cmd
}


# ─────────────────────────────────────────────
# npx
# ─────────────────────────────────────────────

npx() {
  if (( $# == 0 )); then
    command npx
    return $?
  fi

  local -a original_cmd bun_cmd

  original_cmd=(npx "$@")
  bun_cmd=(bunx "$@")

  if ! _maybebun_check; then
    command npx "$@"
    return $?
  fi

  _maybebun_choose "npx" original_cmd bun_cmd
}
