#!/usr/bin/env bash
# Exercise packaging and routing decisions with tiny fixtures; no kernel compilation.
set -eo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
sed -n '/^post_build() {/,/^upload() {/p' "$ROOT/ckbuild.sh" | sed '$d' > "$TMP/packaging.sh"
sed -n '/^ensure_rule() {/,/^refresh_routes() {/p' "$ROOT/extras/start-docker.sh" | sed '$d' > "$TMP/routing.sh"
fail() { echo "$*" >&2; exit 1; }
source "$TMP/routing.sh"
ip() {
    if [[ $* == '-4 rule show' ]]; then
        printf '%s\n' "$RULES"
    else
        printf '%s\n' "$*" >> "$TMP/ip-calls"
    fi
}
RULES='5000: from all lookup main'
ensure_rule 5000 'from all lookup main' from all lookup main
[[ ! -e "$TMP/ip-calls" ]]
RULES='5000: from all lookup vpn'
if (ensure_rule 5000 'from all lookup main' from all lookup main); then
    fail 'Conflicting route accepted'
fi
RULES=''
ensure_rule 5000 'from all lookup main' from all lookup main
grep -q 'rule add pref 5000' "$TMP/ip-calls"

package_case() (
    set -eo pipefail
    local dev=$1 installer=$2 zip_failure=${3:-0} missing=${4:-0}
    KDIR="$TMP/$dev-$installer-$zip_failure-$missing"
    mkdir -p "$KDIR/out" "$KDIR/AnyKernel3" "$KDIR/templates/$dev"
    cd "$KDIR"
    # The bundled template intentionally supports Redmi only.
    printf 'device.name1=ginkgo\ndevice.name2=willow\n' > AnyKernel3/anykernel.sh
    printf 'device.name1=%s\n' "$installer" > "templates/$dev/anykernel.sh"
    if [[ $dev == mitrinket ]]; then
        printf 'device.name2=ginkgo\ndevice.name3=willow\n' >> "templates/$dev/anykernel.sh"
    fi
    CODENAME=$dev
    AK3_DIR="$KDIR/templates"
    ZIP_PATH="$KDIR/test.zip"
    OUT_IMAGE="$KDIR/out/Image"
    OUT_DTBO="$KDIR/out/dtbo.img"
    OUT_DTB="$KDIR/out/dtb"
    DTBO_TMP="$KDIR/out"
    OUT_DTB_GINKGO="$KDIR/out/dtb-ginkgo"
    OUT_DTB_LAUREL="$KDIR/out/dtb-laurel"
    KBUILD_COMPILER_STRING='fixture compiler'
    printf config > out/.config
    for path in "$OUT_IMAGE" "$OUT_DTBO" "$OUT_DTB" "$OUT_DTB_GINKGO" "$OUT_DTB_LAUREL" "$DTBO_TMP/dtbo-ginkgo.img" "$DTBO_TMP/dtbo-laurel_sprout.img"; do
        printf fixture > "$path"
    done
    [[ $missing == 0 ]] || rm "$OUT_DTB_LAUREL"
    git() { echo fixture-commit; }
    zip() {
        [[ $zip_failure == 0 ]] || return 23
        printf archive > "$2"
    }
    source "$TMP/packaging.sh"
    post_build
    [[ -s releases/test.zip && -s releases/test.zip.manifest && -s releases/test.zip.config ]]
)
export TMP
export -f package_case
package_case ginkgo ginkgo
package_case laurel_sprout laurel_sprout
package_case mitrinket laurel_sprout
if bash -c 'package_case "$@"' _ laurel_sprout ginkgo; then fail 'Wrong-device installer accepted'; fi
if bash -c 'package_case "$@"' _ ginkgo ginkgo 1; then fail 'ZIP failure accepted'; fi
if bash -c 'package_case "$@"' _ mitrinket laurel_sprout 0 1; then fail 'Missing unified artifact accepted'; fi
# No failure path should upload logs automatically.
! sed -n '/^post_build() {/,/^upload() {/p' "$ROOT/ckbuild.sh" | grep -q 'curl '
sed -n '/^build() {/,/^dtbo_build() {/p' "$ROOT/ckbuild.sh" | sed '$d' > "$TMP/build.sh"
# A failing configure command must propagate through tee and stop before compilation.
if bash -c '
    set -eo pipefail
    cd "$TMP"
    DO_REGEN=1 DO_KSU=0 DO_SUKI=0 DEFCONFIG=fixture
    make() { echo "intentional configure failure"; return 23; }
    source "$TMP/build.sh"
    build
'; then
    fail 'Configure pipeline failure was ignored'
fi
echo 'Script regression checks passed'
