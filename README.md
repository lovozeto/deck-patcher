# Deck Patcher

A Flatpak GUI application for the Steam Deck that lets you browse, apply, and
revert community-maintained patches for games and apps.

## What is Deck Patcher?

Deck Patcher is a patch manager designed for the Steam Deck. It connects to a
community patch registry, lets you browse available patches for your installed
games and apps, and applies them safely with automatic backups and rollback.

## Features

- **Patch browser** — browse available game and app patches organized by
  category, with README previews and tag filtering
- **Apply / revert** — one-tap apply or revert with automatic `.bak` backups
  before every change
- **Auto-detect outdated patches** — a background systemd watcher checks patch
  markers after every Steam update and re-applies eligible patches automatically
- **Multi-account support** — manage patches independently for each Steam
  account on the same device
- **App setup wizard** — install non-Steam apps (via Flatpak), add library
  shortcuts, pick SteamGridDB artwork, and apply configuration patches in one
  flow
- **SteamGridDB artwork picker** — search and apply hero banners, grids, logos,
  and icons for any shortcut in your library
- **Activity log** — full chronological history of every apply, revert, and
  re-apply action per patch and account

## Installation

### Method 1 — One-line installer (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/lovozeto/deck-patcher/main/install.sh | bash
```

### Method 2 — Download the Flatpak bundle manually

1. Go to [Releases](https://github.com/lovozeto/deck-patcher/releases/latest)
2. Download `deck-patcher.flatpak`
3. Run: `flatpak install --user --bundle deck-patcher.flatpak`

### Method 3 — Add the Flatpak repository

```bash
flatpak remote-add --user --if-not-exists deck-patcher \
  https://lovozeto.github.io/deck-patcher/repo
flatpak install --user deck-patcher com.github.lovozeto.DeckPatcher
```

## Related repositories

- **Patch registry**: [lovozeto/deck-patches](https://github.com/lovozeto/deck-patches)
  — the community patch index, `apply.sh` / `revert.sh` scripts, and README files
- **Decky plugin** (parked): [lovozeto/deck-patcher-decky](https://github.com/lovozeto/deck-patcher-decky)

## Requirements

- SteamOS 3.5 or later
- Flatpak (pre-installed on Steam Deck)
- Internet connection for registry sync and SteamGridDB artwork

## Development setup

```bash
git clone https://github.com/lovozeto/deck-patcher
cd deck-patcher

python3 -m venv .venv
source .venv/bin/activate
pip install vdf requests python-steamgriddb jsonschema ruff mypy pytest

# Lint
ruff check src/

# Type check
mypy --strict src/

# Tests
pytest tests/ -v
```

To build and install the Flatpak locally:

```bash
flatpak-builder --user --install build-dir com.github.lovozeto.DeckPatcher.yml
flatpak run com.github.lovozeto.DeckPatcher
```

## License

MIT — see [LICENSE](LICENSE).
