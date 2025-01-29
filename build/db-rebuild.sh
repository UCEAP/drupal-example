#!/bin/bash

# Set the things
HOST=${DB_HOST:-${MYSQL_HOST:-127.0.0.1}}
USER=${DB_USER:-${MYSQL_USER:-root}}
PASSWORD=${DB_PASSWORD:-${MYSQL_PASSWORD:-}}
DATABASE=${DB_NAME:-${MYSQL_DATABASE:-database}}
PORT=${DB_PORT:-${MYSQL_TCP_PORT:-3306}}
WEBROOT=${LANDO_WEBROOT:-$(dirname $(dirname $(realpath $0)))}
DRUSHTASK=${DRUSH_TASK:-myeap-deploy}
TERMINUSENV=${TERMINUS_ENV:-dev}

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
 echo "$FILE"
# Test if FILE is set if not download pantheon's production db to temp file.
if [ -z "$FILE" ]; then
  # generate temp file
  FILE=$(mktemp) || exit 1
  # grab latest production db backup.
  curl `terminus backup:get --element=db myeap2.$TERMINUSENV` --output $FILE
  function cleanup {
    rm "$FILE"
  }
  trap cleanup EXIT
fi

# Set positional arguments in their proper place
eval set -- "$FILE"
CMD="$FILE"
PV=""

# Validate we have a file
if [ ! -f "$FILE" ]; then
  echo "File $FILE not found!"
  exit 1;
fi

# reset db back to default repo state
echo "Dropping and re-creating $DATABASE @ $HOST:$PORT as $USER..."
if [ ! -z "$PASSWORD" ]; then
  eval "mysqladmin -h$HOST -u$USER -p$PASSWORD drop $DATABASE -f"
  eval "mysqladmin -h$HOST -u$USER -p$PASSWORD create $DATABASE -f"
else
  eval "mysqladmin -h$HOST -u$USER drop $DATABASE -f"
  eval "mysqladmin -h$HOST -u$USER create $DATABASE -f"
fi

# Inform the user of things
echo "Preparing to import $FILE into $DATABASE on $HOST:$PORT as $USER..."

# Check to see if we have any unzipping options or GUI needs
if command -v gunzip >/dev/null 2>&1 && gunzip -t $FILE >/dev/null 2>&1; then
  echo "Gunzipped file detected!"
  if command -v pv >/dev/null 2>&1; then
    CMD="pv $CMD"
  else
    CMD="cat $CMD"
  fi
  CMD="$CMD | gunzip"
elif command -v unzip >/dev/null 2>&1 && unzip -t $FILE >/dev/null 2>&1; then
  echo "Zipped file detected!"
  CMD="unzip -p $CMD"
  if command -v pv >/dev/null 2>&1; then
    CMD="$CMD | pv"
  fi
else
  if command -v pv >/dev/null 2>&1; then
    CMD="pv $CMD"
  else
    CMD="cat $CMD"
  fi
fi

# Put the pieces together
CMD="$CMD | mysql -h $HOST -P $PORT --protocol tcp -u $USER"
if [ ! -z "$PASSWORD" ]; then
   CMD="$CMD -p$PASSWORD $DATABASE"
else
  CMD="$CMD $DATABASE"
fi

# Import
echo "Importing $FILE..."
eval "$CMD"
echo "Import completed with status code $?"

# update db with latest code/config changes
echo "Running drush:$DRUSHTASK to update DB with latest configs and baseline migrations."
eval "cd $WEBROOT && drush $DRUSHTASK"
