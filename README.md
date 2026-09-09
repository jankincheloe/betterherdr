# Betterherdr

<p align="center">
  <img src="assets/logo.png" alt="Betterherdr" width="100" />
</p>

Betterherdr is a small fork of [Herdr](https://github.com/herdrdev/herdr), the terminal runtime for coding agents. It stays close to upstream Herdr and adds a few personal quality-of-life tweaks.

The main addition is simple multi-account support for the Codex CLI through [`setup-codex-accounts.sh`](./setup-codex-accounts.sh).

## What is Herdr?

Herdr keeps coding-agent terminals running in a background server, shows which agents are working or waiting for input, and lets you manage several agents, panes, workspaces, and machines from one terminal UI.

For the complete feature overview and documentation, visit [herdr.dev](https://herdr.dev/) and the [upstream Herdr repository](https://github.com/herdrdev/herdr).

## Build Betterherdr

Clone the fork and build it with Rust:

```bash
git clone https://github.com/jankincheloe/betterherdr.git
cd betterherdr
cargo build --release
```

The resulting binary is at `target/release/herdr`. To install it into Cargo's binary directory instead, run:

```bash
cargo install --path .
```

Start Herdr in the directory where you want to work:

```bash
herdr
```

Upstream usage documentation is available in the [Herdr quick start](https://herdr.dev/docs/quick-start/).

## Codex multi-account setup

The account helper works with the Codex CLI on its own; Herdr is not required. The Herdr-specific workflow is covered in the next section.

### Requirements

- macOS or Linux
- Bash to run the setup script
- Zsh as your interactive shell; the script updates `~/.zshrc`
- The [`codex`](https://github.com/openai/codex) command installed and available on `PATH`

### Run the setup

From the Betterherdr repository:

```bash
./setup-codex-accounts.sh
```

The script asks how many accounts you want and requests a short name for each one, for example `work` and `personal`. Account names may contain letters, numbers, underscores, and hyphens, and must begin with a letter or number.

After setup, reload your shell configuration:

```bash
source ~/.zshrc
```

Authenticate each account separately:

```bash
codex work login
codex personal login
```

Then launch Codex with the account you want:

```bash
codex work
codex personal
```

Any additional Codex arguments are passed through after the account name:

```bash
codex work -C ~/Projects/work-project
codex personal -C ~/Projects/personal-project
```

Running `codex` without a configured account name continues to use the normal default Codex configuration:

```bash
codex
```

### What the script changes

Each account receives an independent Codex home directory:

```text
~/.codex-accounts/work
~/.codex-accounts/personal
```

The script configures Codex to keep credentials in files inside the corresponding account directory and adds a small `codex()` wrapper function to `~/.zshrc`. It creates a timestamped backup such as `~/.zshrc.codex-backup.<timestamp>` before changing the file.

You can run the script again to change the configured account names. On each run, enter every account that should remain available through the wrapper. Existing account directories and credentials are not deleted.

## Use multiple Codex accounts in Herdr

Reload `~/.zshrc` in any already-open Zsh session before using the wrapper. New Zsh panes load it automatically:

```bash
source ~/.zshrc
herdr
```

Inside Herdr, open a pane for each project or account and launch the desired profile exactly as you would in a normal terminal:

```bash
# Work pane
cd ~/Projects/work-project
codex work

# Personal pane
cd ~/Projects/personal-project
codex personal
```

Each Codex process uses its own login, configuration, and session data while Herdr continues to manage the panes normally.

For scripts or other non-interactive launches, set `CODEX_HOME` directly instead of relying on the Zsh function:

```bash
CODEX_HOME="$HOME/.codex-accounts/work" codex -C ~/Projects/work-project
```

### Install the Herdr Codex integration for every account

Herdr's optional Codex integration records native session identity so supported sessions can be resumed after a Herdr server restart. Because every account has a separate `CODEX_HOME`, install the integration once for each profile:

```bash
CODEX_HOME="$HOME/.codex-accounts/work" herdr integration install codex
CODEX_HOME="$HOME/.codex-accounts/personal" herdr integration install codex
```

Repeat that command for any additional accounts. You can inspect an account's integration status with:

```bash
CODEX_HOME="$HOME/.codex-accounts/work" herdr integration status
```

This integration step is optional for simply running multiple accounts, but recommended if you want Herdr's Codex session restore support.

## Development

```bash
just test
just check
```

See [`AGENTS.md`](./AGENTS.md) and [`CONTRIBUTING.md`](./CONTRIBUTING.md) before contributing changes.

## Upstream and license

Betterherdr is based on [herdrdev/herdr](https://github.com/herdrdev/herdr). Most of the project, its documentation, and its design belong to the upstream Herdr project; this fork only carries a small set of tweaks.

Licensed under the [Apache License 2.0](LICENSE).
