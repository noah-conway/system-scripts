#!/bin/bash

set -o errexit -o nounset -o pipefail

readonly ENV_FILE="/home/noah/dev/system-scripts/restic-backup-dev/.restic.env"

readonly PATHS_TO_BACKUP=(
        "/home/noah/books"
        "/home/noah/books2"
)

# Restic retention policy
readonly KEEP_DAILY=7
readonly KEEP_WEEKLY=4
readonly KEEP_MONTHLY=12
readonly KEEP_YEARLY=3

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
  local message="RESTIC ERROR ON $HOSTNAME: Command $command failed with exit code $exit_code on $(date +"%Y-%m-%d %H:%M:%S")"
  echo $LOG_BODY

  EXIT_CODE=1
}

trap 'error_handler' ERR

#send healthcheck start
log_output "$(date) Starting $HOSTNAME restic backup script\nPerforming pre-flight checks..."

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Env file not found"
  exit 1
fi
source "${ENV_FILE}"

if [[ -z "${RESTIC_REPOSITORY:-}" ]]; then
  echo "Repo not set"
  exit 1
fi

# backblaze connection check


#run podman DB dumps

log_output "All checks passed\n$(date) Starting restic backup for directories ..."

backup_output=$(restic backup ${PATHS_TO_BACKUP[@]} --dry-run)
log_output "Restic: $backup_output"

#prune backups
log_output "$(date) Starting prune"

#send healthcheck finish
