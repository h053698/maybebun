brew install gum >/dev/null 2>&1

python3 - <<'PY'
from pathlib import Path
import re

p = Path.home() / ".zshrc"
s = p.read_text() if p.exists() else ""

# Remove previous versions
patterns = [
    r'\n*# npm / Bun chooser\nnpm\(\) \{.*?\n\}\n',
    r'\n*# Block npm installs and suggest Bun instead\nnpm\(\) \{.*?\n\}\n',
    r'\n*# Suggest Bun equivalents for npm commands\nnpm\(\) \{.*?\n\}\n',
    r'\n*# maybebun-start.*?# maybebun-end\n?',
    r'\n*# npm-bun-smart-start.*?# npm-bun-smart-end\n?',
]

for pattern in patterns:
    s = re.sub(pattern, '\n', s, flags=re.S)

p.write_text(s.rstrip() + "\n")
PY

cat >> ~/.zshrc <<'EOF'

# maybebun-start

_maybebun_choose() {
  local original="$1"
  local converted="$2"
  local label="${3:-npm}"

  echo

  local choice
  choice=$(
    printf 'Bun\t%s\n%s\t%s\n' "$converted" "$label" "$original" |
    gum choose \
      --header "Run with" \
      --footer "↑↓ move  •  enter select  •  esc cancel" \
      --cursor "❯ " \
      --cursor-prefix "  " \
      --selected-prefix "❯ " \
      --unselected-prefix "  "
  )

  [[ -z "$choice" ]] && return 130

  echo

  if [[ "$choice" == Bun$'\t'* ]]; then
    eval "$converted"
  else
    if [[ "$label" == "npx" ]]; then
      command npx ${(z)${original#npx }}
    else
      command npm ${(z)${original#npm }}
    fi
  fi
}

npm() {
  local original="npm ${(j: :)${(q)@}}"
  local converted=""
  local args=""

  case "$1" in

    install|i|add)
      if [[ $# -eq 1 ]]; then
        converted="bun install"

      elif [[ "$2" == "-g" || "$2" == "--global" ]]; then
        converted="bun add -g ${(j: :)${(q)@[3,-1]}}"

      elif [[ "$2" == "-D" || "$2" == "--save-dev" ]]; then
        converted="bun add -d ${(j: :)${(q)@[3,-1]}}"

      elif [[ "$2" == "-O" || "$2" == "--save-optional" ]]; then
        converted="bun add --optional ${(j: :)${(q)@[3,-1]}}"

      else
        args="${(j: :)${(q)@[2,-1]}}"
        args="${args//--save-dev/-d}"
        args="${args//--global/-g}"
        converted="bun add $args"
      fi
      ;;

    uninstall|remove|rm|un)
      converted="bun remove ${(j: :)${(q)@[2,-1]}}"
      ;;

    ci)
      converted="bun install --frozen-lockfile"
      ;;

    run|run-script)
      converted="bun run ${(j: :)${(q)@[2,-1]}}"
      ;;

    exec|x)
      converted="bunx ${(j: :)${(q)@[2,-1]}}"
      ;;

    test|t)
      if [[ $# -gt 1 ]]; then
        converted="bun test ${(j: :)${(q)@[2,-1]}}"
      else
        converted="bun test"
      fi
      ;;

    start)
      converted="bun run start"
      ;;

    create)
      converted="bun create ${(j: :)${(q)@[2,-1]}}"
      ;;

    init)
      if [[ "$2" == "-y" || "$2" == "--yes" ]]; then
        converted="bun init -y"
      else
        converted="bun init"
      fi
      ;;

    link)
      converted="bun link ${(j: :)${(q)@[2,-1]}}"
      ;;

    unlink)
      converted="bun unlink ${(j: :)${(q)@[2,-1]}}"
      ;;

    update|up)
      converted="bun update ${(j: :)${(q)@[2,-1]}}"
      ;;

    outdated)
      converted="bun outdated"
      ;;

    *)
      command npm "$@"
      return $?
      ;;
  esac

  _maybebun_choose "$original" "$converted" "npm"
}

npx() {
  local original="npx ${(j: :)${(q)@}}"
  local converted="bunx ${(j: :)${(q)@}}"

  _maybebun_choose "$original" "$converted" "npx"
}

# maybebun-end
EOF

exec zsh
