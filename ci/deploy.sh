#!/usr/bin/env bash
# Deploys a node with a dead man's switch:
#  1. builds the system locally and copies it to the target;
#  2. arms a transient systemd timer on the target that switches back to the
#     current boot generation, unless disarmed within $ROLLBACK_TIMEOUT seconds;
#  3. activates with `nixos-rebuild test`, so the boot entry stays untouched
#     and a hard reboot also lands in the old system;
#  4. reconnects over a fresh SSH session, disarms, and only then makes the
#     new system the boot default.
#
# Usage: ci/deploy.sh <node>
# Needs nix and nixos-rebuild-ng in PATH. Uses $SSH_PRIVKEY_INFRA as the SSH key
# if set, otherwise whatever ssh would use (agent, ~/.ssh).
set -euo pipefail

node=${1:?usage: $0 <node>}
timeout=${ROLLBACK_TIMEOUT:-300}
unit=nixos-deploy-rollback

log() { printf '\e[1mdeploy/%s:\e[0m %s\n' "$node" "$*" >&2; }
fail() { log "$*"; exit 1; }
trap 'log "failed at line $LINENO: $BASH_COMMAND"' ERR

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Plain assignments, so a failing eval stops the script under `set -e`.
# (`nix eval --raw` prints no trailing newline, so `read` gets a here-string.)
# shellcheck disable=SC2016 # Nix interpolation, not shell
settings=$(nix eval --raw ".#nodeMeta.$node.settings" \
  --apply 's: "${s.host} ${toString (s.port or 22)} ${s.user or "root"}"')
read -r host port user <<< "$settings"
target="$user@$host"

host_key=$(nix eval --raw ".#nodeMeta.$node.settings.hostKey")
if [[ $port == 22 ]]; then known=$host; else known="[$host]:$port"; fi
echo "$known $host_key" > "$tmp/known_hosts"

ssh_opts=(
  -p "$port"
  -o BatchMode=yes
  -o StrictHostKeyChecking=yes
  -o "UserKnownHostsFile=$tmp/known_hosts"
  -o ConnectTimeout=15
  -o ServerAliveInterval=5
  -o ServerAliveCountMax=6
)
if [[ -n ${SSH_PRIVKEY_INFRA:-} ]]; then
  (umask 077; printf '%s\n' "$SSH_PRIVKEY_INFRA" > "$tmp/id_ed25519")
  ssh_opts+=(-i "$tmp/id_ed25519" -o IdentitiesOnly=yes)
fi
export NIX_SSHOPTS="${ssh_opts[*]}"

# Every call is a fresh connection, so "reachable" means "a new login works".
remote() { ssh "${ssh_opts[@]}" -o ControlPath=none "$target" "$@"; }

log "building"
system=$(nix build --no-link --print-out-paths --print-build-logs \
  ".#nixosConfigurations.$node.config.system.build.toplevel")

# Copy before arming, so the timer only has to cover activation.
log "copying $system to $target"
nix copy --substitute-on-destination --to "ssh://$target" "$system"

previous=$(remote readlink -f /nix/var/nix/profiles/system)
if [[ $previous == "$system" ]]; then
  log "already the boot default, activating anyway"
fi

# A leftover timer means an interrupted deploy; replace it with ours.
remote "systemctl stop $unit.timer 2>/dev/null; systemctl reset-failed $unit.timer $unit.service 2>/dev/null; true"

log "arming rollback to $previous in ${timeout}s"
remote systemd-run \
  --unit="$unit" \
  --on-active="$timeout" \
  --timer-property=AccuracySec=1s \
  --timer-property=RemainAfterElapse=no \
  --service-type=oneshot \
  --collect \
  --setenv=LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive \
  "$previous/bin/switch-to-configuration" switch

log "activating (test, boot entry untouched)"
activated=true
nixos-rebuild test --no-reexec --store-path "$system" --target-host "$target" || activated=false

reachable=false
for _ in 1 2 3 4 5 6; do
  if remote true; then reachable=true; break; fi
  log "target unreachable, retrying"
  sleep 10
done
$reachable || fail "target unreachable after activation, the timer will roll it back"

if ! $activated; then
  log "activation failed, rolling back now"
  # The armed timer stays as a backup in case this connection drops.
  remote systemd-run \
    --unit="$unit-now" \
    --service-type=exec \
    --collect --wait --pipe --quiet \
    --setenv=LOCALE_ARCHIVE=/run/current-system/sw/lib/locale/locale-archive \
    "$previous/bin/switch-to-configuration" switch \
    || log "immediate rollback failed, the timer will retry"
  remote systemctl stop "$unit.timer" || true
  fail "deploy failed, rolled back to $previous"
fi

remote "systemctl is-active --quiet $unit.timer && systemctl stop $unit.timer" \
  || fail "rollback timer is gone (fired already?), not making $system the boot default"
log "disarmed"

log "making it the boot default"
nixos-rebuild boot --no-reexec --store-path "$system" --target-host "$target"

log "done: $system"
