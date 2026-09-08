# Plugin initialization brief

This tracked document is the durable marker that initialization has completed.
Complete it for every plugin, including tiny, temporary, and local-only work.
Record portable decisions here. Keep machine paths, ports, detected capabilities,
runtime receipts, and private state in clone-local excluded state. Never record
secrets in either artifact.

## Simple interview — required

- **Plugin identity / folder:** `tm-no-auto-pause` / name `No Auto-Pause`
- **Purpose:** Stop Trackmania Turbo from auto-pausing (attract / INSERT COIN / SleepEx) when the window loses focus.
- **Target games:** Trackmania Turbo (OpenplanetTurbo). No-op with a warning on other games.
- **Tested games and Openplanet versions/channels:** Trackmania Turbo, OpenplanetTurbo 1.29.14. Static RE against TrackmaniaTurbo.exe image base 0x400000. First-load 2026-09-08 13:40:39 AEST: patched notify 0x004F1FD0 predicate 0x010D6E40. Alt-tab race-clock confirm still operator/Claude.
- **Publication intent:** public (https://github.com/clankercode/tm-no-auto-pause). Live-verified on Turbo Openplanet 1.29.14 (v0.1.1: 113 s unfocused, Now +112401 ms, no menu).
- **Source, provenance, and AI use:** Newly authored. Patch RVAs from static Ghidra of TrackmaniaTurbo.exe (research/turbo/2026-09-08-Turbo-Unfocus-Pause.md). Dual-licensed Unlicense OR CC0-1.0, same as sibling XertroV plugins. AI-assisted implementation.
- **Paid-feature permissions:** N/A — this does not unlock paid content; it only skips the unfocus pause/throttle.
- **Architecture / module topology:** One plugin module, one `Main.as`.
- **Dependencies:** none
- **Canonical source and build/staging flow:** Source root is this folder (`info.toml` + `src/`). `GAME=turbo ./build.sh dev` stages into `~/OpenplanetTurbo/Plugins/tm-no-auto-pause`.
- **Expected Openplanet callbacks:** `Main`, `Update`, `OnDestroyed`, `OnDisabled`, `RenderMenu`
- **Smallest observable completion gate:** Plugin loads; log line `No Auto-Pause: patched notify ... predicate ...` (or an explicit prologue-mismatch warning).
- **Validation plan:** `openplanet-lsp --game-target TURBO`; stage exact bytes; first-load via RemoteBuild :30002 or manual load once Turbo is free; alt-tab and confirm the race clock still advances.
- **Policy assumptions:** Local memory patch of the process the user already runs. No network, no paid bypass, no deception. Human-controlled if ever published to Openplanet.

## Advanced branches — answer when applicable

Mark unused branches `N/A` with a short reason.

### Assets

- Asset/font/media sources, licenses, permissions, attribution, and packaging: N/A — no assets.

### Dependencies and exports

- Dependency IDs, versions, required/optional behavior, and load order: none
- Why ordinary `exports` are insufficient, if `shared_exports` are proposed: N/A
- Dependent reload/lifetime evidence plan for multi-plugin topology: N/A

### Build, staging, and defines

- Build/staging command and deterministic source-to-output mapping: `GAME=turbo ./build.sh dev` copies `src/*` + `info.toml` (name suffix ` (Dev)`, `defines = ["DEV"]`) into the Turbo Plugins folder named after this directory.
- Preprocessor defines, who expands them, and public/release defaults: Openplanet defines `TURBO` when compiling for Trackmania Turbo. Build.sh may add `DEV`.
- Exact-bytes comparison method: `cmp` of staged `Main.as` against `src/Main.as`.

### Authentication and public configuration

- Secret-store boundary (name the mechanism, never the secret): N/A
- Non-secret public settings and safe defaults: `S_Enabled` default true (keep running when unfocused).
- DEV-only/local-only enablement and shutdown behavior: `OnDestroyed` / `OnDisabled` restore original bytes.

### Packaging and publication preparation

- Package contents and excluded development artifacts: `src/`, `info.toml`, `LICENSE`, this brief. Clone-local `.openplanet/local-state.md` excluded.
- Compatibility, version, changelog, images/accessibility text, and disclosure plan: v0.1.0 Turbo-only; disclose that it patches WndProc-driven focus flags.
- Human decision boundaries for upload, terms, signing, attestation, approval, and publication: do not upload until live-verified.

## Initialization result

- **Tracked brief path:** `INITIALIZATION-BRIEF.md`
- **Clone-local state path (excluded via `.git/info/exclude`):** `.openplanet/local-state.md` (after git init)
- **Manifest and entrypoint:** `info.toml` → `src/Main.as` (Openplanet default)
- **Static diagnostics:** recorded in clone-local state
- **First-load evidence:** `OpenplanetTurbo/Openplanet.log` 13:40:39.347 `Loaded plugin 'tm-no-auto-pause' (version 0.1.0)`; 13:40:39.349 `No Auto-Pause: patched notify 0x004F1FD0 predicate 0x010D6E40`. No later compile error for this plugin.
- **Explicit runtime blocker, if evidence is unavailable:** none for load. Alt-tab keep-running is not live-measured here (would steal the game from an in-race session).
- **Initialization boundary:** feature patches are in `Main.as` because that is the requested plugin behavior, not extra scaffolding.
