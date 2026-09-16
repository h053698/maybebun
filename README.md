# maybeBun

> You typed npm. Maybe Bun?

**maybeBun** is a tiny Zsh helper that intercepts common `npm` and `npx` commands and gives you the option to run their **Bun equivalent instead**.

It doesn't force you to use Bun.  
You choose what actually runs.

<img width="764" height="284" alt="image" src="https://github.com/user-attachments/assets/2cb7cc67-8bcf-44eb-becc-f891d864b93a" />


## What it does

Type an npm command like you normally would:

```bash
npm install hono
```

Instead of running it immediately, maybeBun shows a small interactive prompt:

```text
Run with

❯ Bun  bun add hono
  npm  npm install hono
```

Choose **Bun** and maybeBun runs:

```bash
bun add hono
```

Choose **npm** and your original command runs unchanged:

```bash
npm install hono
```

Press **Esc** to cancel without running anything.

## Installation

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/h053698/maybebun/main/install.sh | zsh
```

Then restart your shell:

```bash
exec zsh
```

That's it.

### Requirements

maybeBun currently requires:

- macOS or another environment running Zsh
- [Bun](https://bun.sh)
- [gum](https://github.com/charmbracelet/gum)

The installer can automatically install `gum` when Homebrew is available.

## Usage

There is nothing new to learn.

Just keep typing the npm commands you already use:

```bash
npm install
npm install react
npm install -D typescript
npm install -g typescript
npm uninstall react
npm ci
npm run dev
npm test
npm start
npm update
npx prisma init
```

When maybeBun knows an appropriate Bun equivalent, it gives you a choice before anything runs.

## Command translation

Some common translations include:

| You type | Bun alternative |
| --- | --- |
| `npm install` | `bun install` |
| `npm install react` | `bun add react` |
| `npm install -D typescript` | `bun add --dev typescript` |
| `npm install -g package` | `bun add --global package` |
| `npm uninstall package` | `bun remove package` |
| `npm ci` | `bun install --frozen-lockfile` |
| `npm run dev` | `bun run dev` |
| `npm test` | `bun run test` |
| `npm start` | `bun run start` |
| `npm update` | `bun update` |
| `npx package` | `bunx package` |

Commands without a clear Bun equivalent are passed directly to npm instead of being translated blindly.

`npm test` maps to `bun run test`, not `bun test`. `npm test` runs the `test`
script from your `package.json`, which is what `bun run test` does — `bun test`
is Bun's own test runner and would ignore that script.

maybeBun only prompts in an interactive terminal. In scripts, pipelines, and
CI, the command you typed runs unchanged instead of blocking on a prompt.

## How it works

maybeBun defines lightweight Zsh wrappers around `npm` and `npx`.

When you enter a supported command, it:

1. Captures the original command.
2. Generates the corresponding Bun command.
3. Shows both options in an interactive selector.
4. Runs only the command you select.

The original npm command remains available, so maybeBun doesn't lock you into Bun.

## Example

```bash
npm install -g @bitkyc08/opencodex
```

maybeBun:

```text
Run with

❯ Bun  bun add --global @bitkyc08/opencodex
  npm  npm install -g @bitkyc08/opencodex
```

Select Bun:

```bash
bun add --global @bitkyc08/opencodex
```

Or select npm to run the command exactly as you entered it.

## Manual installation

Clone the repository:

```bash
git clone https://github.com/h053698/maybebun.git ~/.maybebun
```

Then add this to your `~/.zshrc`:

```bash
source "$HOME/.maybebun/maybebun.zsh"
```

Reload Zsh:

```bash
exec zsh
```

## Uninstall

Remove this line from `~/.zshrc`:

```bash
source "$HOME/.maybebun/maybebun.zsh"
```

Then remove the installation directory:

```bash
rm -rf ~/.maybebun
```

Restart your shell:

```bash
exec zsh
```

## Why?

Because sometimes you type:

```bash
npm install
```

and realize a second later:

```bash
bun install
```

would have been nice.

maybeBun gives you that second back.

## License

MIT
