# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

YASPRS (Yet Another Simple PS4 Package Remote Sender) is a small Node.js/Express web app that lets you browse `.pkg` files on the host machine and tell a PS4 running Remote Package Installer (HEN/GoldHEN) to download and install them over the LAN. It is meant for trusted local networks only and has no authentication.

## Commands

```bash
npm install     # install dependencies (express, axios, cors)
npm start       # run server.js on http://localhost:3001 (override with PORT env var)
```

Docker: `cp .env.example .env` (set `HOST_IP` and `PKG_DIR`), then `docker compose up -d --build`. The container stores config in a `/config` volume and mounts packages read-only at `/pkgs`, which must then be set as the PKG Base Path in the UI. `entrypoint.sh` starts as root, chowns `/config` to `PUID:PGID`, and drops privileges with `su-exec`. `scanPkgs` silently skips unreadable directories, so an empty package list in Docker usually means `PUID`/`PGID` can't read `PKG_DIR`.

There is no build step, bundler, linter, or test suite. The frontend is plain ES modules served as static files, so changes take effect on browser reload; server changes need a restart. Requires Node.js 16+.

## Architecture

**Backend — `server.js` (single file).** Express serves `src/` as static files and exposes:

- `GET/POST /api/config` — read/merge-save config at `$XDG_CONFIG_HOME/yasprs/profile.json` or `~/.config/yasprs/profile.json`. Config is re-read from disk on every request (no in-memory cache).
- `GET /api/pkgs` — recursively scans `pkgBasePath` for `*.pkg` files.
- `GET /api/network` — lists the host's non-internal IPv4 addresses.
- `POST /api/send` — the core flow (below).
- `GET /pkg-files/:filename` — serves a package file to the PS4.

**Send flow:** the browser posts an absolute `pkgPath` → the server builds a URL `http://<host-ip>:<PORT>/pkg-files/<basename>` and POSTs `{"type":"direct","packages":[url]}` to `http://<ps4ip>:12800/api/install` → the PS4 then downloads the file from `/pkg-files/`. Things to keep in mind when changing this:

- The host IP comes from the `HOST_IP` env var if set (required in Docker, where the detected IP is the container's). Otherwise it's the *first* non-internal IPv4 found by `getLocalIP()`, which may be the wrong interface on multi-NIC machines.
- `/pkg-files/` resolves files by **basename only**, searching recursively under `pkgBasePath` (`findFile`), so two packages with the same filename in different subfolders collide — the first match wins.
- The PS4 request body is a JSON string sent with `Content-Type: application/x-www-form-urlencoded`; this is what Remote Package Installer expects, so don't "fix" it.
- The PS4 port is hardcoded to `12800`. The UI saves a `ps4port` field and the default config has `serverPort`, but the server ignores both.

**Frontend — `src/`.** Vanilla JS ES modules with no framework:

- `js/app.js` — entry point; tab switching (switching to Packages triggers a scan) and event wiring.
- `js/api.js` — `fetch` wrapper that returns parsed JSON or `null` (and shows a toast) on network errors.
- `js/config.js` / `js/packages.js` — Settings and Packages tabs; packages are rendered as HTML strings via template literals.
- `js/ui.js` — `toast`, `esc` (HTML escaping), and small render helpers. Use `esc()` for any user/filesystem-derived string interpolated into HTML.
- CSS is split into `base.css` (variables/reset), `layout.css`, and `components.css`.

## Conventions

4-space indentation, double quotes, trailing commas (Prettier-style formatting, though no config is committed). The backend uses CommonJS `require`; the frontend uses ES `import`/`export`.
