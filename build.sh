#!/usr/bin/env bash
# Stage / hot-reload for Trackmania Turbo (OpenplanetTurbo).
#   ./build.sh [dev|release]
# Env: TURBO_PLUGINS_DIR (default ~/OpenplanetTurbo/Plugins), SKIP_LSP=1, SKIP_RELOAD=1
set -euo pipefail
cd "$(dirname "$0")"
mode="${1:-dev}"
plugins_dir="${TURBO_PLUGINS_DIR:-$HOME/OpenplanetTurbo/Plugins}"
op_dir="$(dirname "$plugins_dir")"
slug="$(basename "$PWD")"
name="$(grep -m1 '^name' info.toml | cut -d= -f2 | tr -d ' "')"
version="$(grep -m1 '^version' info.toml | cut -d= -f2 | tr -d ' "')"

if [[ "${SKIP_LSP:-0}" != "1" ]] && command -v openplanet-lsp >/dev/null; then
  echo "== openplanet-lsp check (TURBO)"
  openplanet-lsp check --game-target TURBO --plugins-dir "$plugins_dir" --plugins-dir "$(dirname "$PWD")" . || {
    echo "!! openplanet-lsp reported errors (SKIP_LSP=1 to bypass)"; exit 1; }
fi

case "$mode" in
  dev)
    dest="$plugins_dir/$slug"
    mkdir -p "$dest"
    rm -rf "${dest:?}"/*
    cp -R src/* "$dest/"
    cp info.toml "$dest/info.toml"
    sed -i 's/^\(name[ \t="]*\)\(.*\)"/\1\2 (Dev)"/' "$dest/info.toml"
    sed -i 's/^#__DEFINES__/defines = ["DEV"]/' "$dest/info.toml"
    echo "== staged $name $version -> $dest"
    if [[ "${SKIP_RELOAD:-0}" != "1" ]] && command -v tm-remote-build >/dev/null; then
      rb_port=30002
      rb_host="$(ss -ltnH 2>/dev/null | awk -v p=":$rb_port\$" '$4 ~ p { sub(/:[0-9]+$/, "", $4); print $4; exit }')"
      if [[ -n "$rb_host" ]]; then
        [[ "$rb_host" == "0.0.0.0" || "$rb_host" == "*" ]] && rb_host="127.0.0.1"
        echo "== tm-remote-build load folder $slug (OpenplanetTurbo @ $rb_host:$rb_port)"
        tm-remote-build load folder "$slug" -op OpenplanetTurbo --host "$rb_host" -d "$op_dir" -l 3 -i 0.5 \
          || echo "!! remote load failed (see $op_dir/Openplanet.log)"
      else
        echo "!! RemoteBuild (:$rb_port) not listening; load the plugin manually"
      fi
    fi
    ;;
  release)
    out="$slug-$version.op"
    rm -f "$out"
    (cd src && 7z a -tzip "../$out" ./* >/dev/null)
    7z a -tzip "$out" info.toml >/dev/null
    echo "== built $out"
    ;;
  *) echo "usage: $0 [dev|release]"; exit 2;;
esac
