#!/bin/bash
#
# editbootconfig hook: fix BLS (Boot Loader Specification) entries
# before kiwi syncs the image root to disk and runs grub2-mkconfig.
#
# On RHEL 8, grub2-mkconfig's 10_linux_bls script reads BLS entries
# and inlines them as menuentry blocks in grub.cfg. Kernel packages
# installed in the kiwi build chroot produce BLS entries with the
# build-root path prefix (e.g. /var/tmp/.../boot/vmlinuz-...) and
# the build host's /proc/cmdline in the options field.
#
# This script corrects those entries so that grub2-mkconfig produces
# a valid grub.cfg.  On RHEL 9+ grub2-mkconfig emits a blscfg command
# instead of inlining, so this script is a harmless no-op there.
#
# Runs non-chrooted from the image root directory.
# Args: $1 = filesystem  $2 = boot_partition_id  (standard kiwi hook)
#
set -euo pipefail

ENTRIES_DIR="boot/loader/entries"
if [[ ! -d "$ENTRIES_DIR" ]]; then
    exit 0
fi

entries=("$ENTRIES_DIR"/*.conf)
if [[ ! -f "${entries[0]}" ]]; then
    exit 0
fi

# All Cloud-Base-Generic profiles use bootpartition="true", so BLS
# linux/initrd paths must be relative to the boot partition root (/).
# Adjust the prefix below to /boot if bootpartition="false".
BOOT_PREFIX="/"

# config.bootoptions is written by kiwi before this hook runs and
# contains the full kernel command line (including root=UUID=...).
BOOT_OPTS=""
if [[ -f config.bootoptions ]]; then
    BOOT_OPTS="$(tr -s ' ' < config.bootoptions)"
    BOOT_OPTS="${BOOT_OPTS%$'\n'}"
fi

changed=0
for entry in "${entries[@]}"; do
    [[ -f "$entry" ]] || continue

    tmpfile=$(mktemp "${entry}.XXXXXX")
    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            linux\ *|initrd\ *)
                key="${line%% *}"
                basename="${line##*/}"
                echo "${key} ${BOOT_PREFIX}${basename}"
                ;;
            options\ *)
                if [[ -n "$BOOT_OPTS" ]]; then
                    echo "options ${BOOT_OPTS}"
                else
                    echo "$line"
                fi
                ;;
            *)
                echo "$line"
                ;;
        esac
    done < "$entry" > "$tmpfile"
    mv "$tmpfile" "$entry"
    changed=1
done

if [[ "$changed" -eq 1 ]]; then
    echo "el8-bls-editbootconfig.sh: BLS entries fixed"
fi
