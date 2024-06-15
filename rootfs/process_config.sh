#!/bin/bash

# Define a function that can be sourced in multiple scripts
process_config() {
    local src="$1"
    local dest="$2"
    local tmp_file; tmp_file=$(mktemp)

    # shellcheck disable=SC2002
    if ! cat "$src" | envsubst "$(env | cut -d= -f1 | sed -e 's/^/$/')" | tee "$tmp_file" > /dev/null; then
        printf "Error processing config %s\n" "$src" >&2
        return 1
    fi

    if ! mv "$tmp_file" "$dest"; then
        printf "Error moving file from %s to %s\n" "$tmp_file" "$dest" >&2
        return 1
    fi
}