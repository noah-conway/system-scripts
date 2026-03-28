#!/bin/bash


readonly ENV_FILE="/home/noah/dev/system-scripts/restic-backup-dev/.restic.env"


#readonly START_HEALTHCHECK_URL
#readonly END_HEALTHCHECK_URL

LOG_BODY=""
EXIT_CODE=0

log_output() {
# Appends output to LOG_BODY to send an alert, but also prints it to stdout
  local message="${1}"
  echo -e "${message}"
  LOG_BODY+=$"${message}\n"
}

send_alert() {
  echo "SENDING ALERT"
}

error_handler() {
  local exit_code=$?
  local command="$BASH_COMMAND"
  local message="RESTIC ERROR ON HOST '$HOSTNAME': Command '$command' failed with exit code $exit_code on $(date +"%Y-%m-%d %H:%M:%S")"
  log_output "$message"
  send_alert
}


set -o errexit -o nounset -o pipefail
trap 'error_handler' ERR

#send healthcheck start

echo -e "$(date) Starting $HOSTNAME restic backup script\nPerforming pre-flight checks..."

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "FATAL ERROR: .env file not found" >&2
  false
fi
source "${ENV_FILE}"

if [[ -z "${RESTIC_REPOSITORY:-}" ]]; then
  echo "FATAL ERROR: Restic repo not set" >&2
  false
fi

mkdir -p $RESTIC_CACHE

#run podman DB dumps

echo -e "All checks passed\n$(date) Starting restic backup to ${RESTIC_REPOSITORY}..."
restic backup ${PATHS_TO_BACKUP[@]} --json

# check backups
echo -e "Backup successful\n$(date) Validating ${CHECK_SUBSET_G}G subset of backups..."
restic check --with-cache --read-data-subset=${CHECK_SUBSET_G}G --json

echo -e "Validation successful\n$(date) Pruning old snapshots per retention policy..."
restic forget --prune --keep-daily $KEEP_DAILY --keep-weekly $KEEP_WEEKLY --keep-monthly $KEEP_MONTHLY --keep-yearly $KEEP_YEARLY --json

echo -e "Restic prune successful\nBackup script successful"
#send healthcheck finish
exit 0
