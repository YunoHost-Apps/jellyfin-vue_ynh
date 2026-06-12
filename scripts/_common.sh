#!/bin/bash

#=================================================
# COMMON VARIABLES AND CUSTOM HELPERS
#=================================================

_patch_config_json() {
    sourcedir=$1

    # Required for sub-path installation
    sed -i \
        "s|'/config.json'|import.meta.env.BASE_URL + 'config.json'|" \
        "$1/packages/frontend/src/utils/external-config.ts"
}

_pnpm_build_install() {
    sourcedir=$1
    targetdir=$2
    subpath=$3

    pushd "$sourcedir/packages/frontend" || ynh_die "Could not pushd $sourcedir/packages/frontend"
        export CYPRESS_INSTALL_BINARY=0
        ynh_hide_warnings corepack enable && corepack prepare pnpm@10 --activate
        ynh_hide_warnings ynh_exec_as_app CYPRESS_INSTALL_BINARY=0 NODE_OPTIONS="--max-old-space-size=3000" corepack pnpm install --frozen-lockfile --aggregate-output
        ynh_hide_warnings ynh_exec_as_app CYPRESS_INSTALL_BINARY=0 NODE_OPTIONS="--max-old-space-size=3000" pnpm build
        ynh_hide_warnings ynh_exec_as_app pnpm store prune
    popd || ynh_die "Could not popd"

    ynh_safe_rm "$targetdir"
    mv "$sourcedir/packages/frontend/dist" "$targetdir"
}

_list_jellyfin_urls() {
    yunohost app list --full --json \
        | jq -r '.apps[] | select(.manifest.id=="jellyfin") | .domain_path'
}

PYTHON_APPEND_TO_SERVER_URLS='
import sys
import json
file = sys.argv[1]
url = sys.argv[2]
with open(file, encoding="utf-8") as configfile:
    data = json.load(configfile)
if url not in data["defaultServerURLs"]:
    data["defaultServerURLs"].append(url)
with open(file, "w", encoding="utf-8") as configfile:
    configfile.write(json.dumps(data, indent=2))
'

_append_to_server_urls() {
    python3 -c "$PYTHON_APPEND_TO_SERVER_URLS" "$@"
}
