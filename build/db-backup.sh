#!/bin/bash

# Set the things
HOST=${DB_HOST:-localhost}
USER=${DB_USER:-${MYSQL_USER:-root}}
PASSWORD=${DB_PASSWORD:-${MYSQL_PASSWORD:-}}
DATABASE=${DB_NAME:-${MYSQL_DATABASE:-database}}
PORT=${DB_PORT:-3306}
MOUNT=${LANDO_MOUNT:-default_value}
WEBROOT=${LANDO_WEBROOT:-default_value}
DRUSHTASK=${DRUSH_TASK:-myeap-deploy}
TERMINUSENV=${TERMINUS_ENV:-dev}
BACKUPPATH=${BACKUP_PATH:-~/Sites}
# PARSE THE ARGZZ
# TODO: compress the mostly duplicate code below?
while (( "$#" )); do
  case "$1" in
    -h|--host|--host=*)
      if [ "${1##--host=}" != "$1" ]; then
        HOST="${1##--host=}"
        shift
      else
        HOST=$2
        shift 2
      fi
      ;;
    -u|--user|--user=*)
      if [ "${1##--user=}" != "$1" ]; then
        USER="${1##--user=}"
        shift
      else
        USER=$2
        shift 2
      fi
      ;;
    -p|--password|--password=*)
      if [ "${1##--password=}" != "$1" ]; then
        PASSWORD="${1##--password=}"
        shift
      else
        PASSWORD=$2
        shift 2
      fi
      ;;
    -d|--database|--database=*)
      if [ "${1##--database=}" != "$1" ]; then
        DATABASE="${1##--database=}"
        shift
      else
        DATABASE=$2
        shift 2
      fi
      ;;
    -P|--port|--port=*)
      if [ "${1##--port=}" != "$1" ]; then
        PORT="${1##--port=}"
        shift
      else
        PORT=$2
        shift 2
      fi
      ;;
      -D|--drush-task|--drush-task=*)
        if [ "${1##--drush-task=}" != "$1" ]; then
          DRUSHTASK="${1##--drush-task=}"
          shift
        else
          DRUSHTASK=$2
          shift 2
        fi
        ;;
    --)
      shift
      break
      ;;
    -*|--*=)
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *)
      FILE="$(pwd)/$1"
      shift
      ;;
  esac
done
# Test if FILE exists if not touch it to gzip to it later.
if [ -z "$FILE" ]; then
  FILENAME="$DATABASE.$(date +%F.%H%M%S).sql.gz"
  eval  "touch -c $BACKUPPATH/$FILENAME"
  FILE="$BACKUPPATH/$FILENAME"
fi
echo "$FILE"

# reset db back to default repo state
echo "Exporting and gzipping $DATABASE @ $HOST:$PORT as $USER to file:$FILE"
if [ ! -z "$PASSWORD" ]; then
  eval "mysqldump  -h $HOST -P $PORT --protocol=tcp -u $USER -p$PASSWORD $DATABASE | gzip > $FILE"
else
  eval "mysqldump -h $HOST -P $PORT --protocol=tcp -u $USER  $DATABASE | gzip > $FILE"
fi
