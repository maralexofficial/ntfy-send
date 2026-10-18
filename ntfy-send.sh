#!/bin/bash

ENV_FILE="${NTFY_ENV_FILE:-/etc/ntfy-send/.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "Env file not found: $ENV_FILE"
  exit 1
fi

PRIORITY=""
TAGS=""
TITLE=""
CUSTOM_TOPIC=""

POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
  --prio=*)
    PRIORITY="${1#--prio=}"
    shift
    ;;
  --tags=*)
    TAGS="${1#--tags=}"
    shift
    ;;
  --topic=*)
    CUSTOM_TOPIC="${1#--topic=}"
    shift
    ;;
  -h|--help)
    echo "Usage: $(basename "$0") [topic|DEFAULT] [title] \"message\" [--topic=NAME] [--prio=1-5] [--tags=a,b]"
    exit 0
    ;;
  *)
    POSITIONAL+=("$1")
    shift
    ;;
  esac
done

set -- "${POSITIONAL[@]}"

if [ "$#" -lt 1 ]; then
  echo "You need at least a message."
  exit 1
fi

case "$#" in
1)
  TOPIC="$DEFAULT_TOPIC"
  MESSAGE="$1"
  ;;
2)
  if [[ "${1^^}" == "DEFAULT" ]]; then
    TOPIC="$DEFAULT_TOPIC"
    MESSAGE="$2"
  else
    TOPIC="$1"
    MESSAGE="$2"
  fi
  ;;
3)
  if [[ "${1^^}" == "DEFAULT" ]]; then
    TOPIC="$DEFAULT_TOPIC"
    TITLE="$2"
    MESSAGE="$3"
  else
    TOPIC="$1"
    TITLE="$2"
    MESSAGE="$3"
  fi
  ;;
*)
  echo "Too many arguments."
  exit 1
  ;;
esac

if [ -n "$CUSTOM_TOPIC" ]; then
  TOPIC="$CUSTOM_TOPIC"
fi

if [ -z "$TOPIC" ]; then
  echo "No topic configured."
  exit 1
fi

CURL_HEADERS=()

if [ -n "$TITLE" ]; then
  CURL_HEADERS+=(-H "Title: $TITLE")
fi

if [ -n "$PRIORITY" ]; then
  CURL_HEADERS+=(-H "X-Priority: $PRIORITY")
fi

if [ -n "$TAGS" ]; then
  CURL_HEADERS+=(-H "X-Tags: $TAGS")
fi

printf "%s" "$MESSAGE" | curl "${CURL_HEADERS[@]}" \
  -H "Authorization: Bearer $TOKEN" \
  --data-binary @- \
  "$SERVER/$TOPIC" \
  >/dev/null 2>&1
