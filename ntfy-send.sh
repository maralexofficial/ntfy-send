#!/bin/bash

ENV_FILE="${NTFY_ENV_FILE:-/etc/ntfy-send/.env}"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "Error: Env file not found: $ENV_FILE" >&2
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

    if [[ -z "$PRIORITY" ]]; then
      echo "Error: --prio requires a non-empty value." >&2
      exit 1
    fi

    shift
    ;;
  --prio)
    echo "Error: --prio requires a value. Use --prio=1-5." >&2
    exit 1
    ;;
  --tags=*)
    TAGS="${1#--tags=}"

    if [[ -z "$TAGS" ]]; then
      echo "Error: --tags requires a non-empty value." >&2
      exit 1
    fi

    shift
    ;;
  --tags)
    echo "Error: --tags requires a value. Use --tags=a,b." >&2
    exit 1
    ;;
  --topic=*)
    CUSTOM_TOPIC="${1#--topic=}"

    if [[ -z "$CUSTOM_TOPIC" ]]; then
      echo "Error: --topic requires a non-empty topic name." >&2
      exit 1
    fi

    shift
    ;;
  --topic)
    echo "Error: --topic requires a value. Use --topic=NAME." >&2
    exit 1
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

if [[ $# -lt 1 ]]; then
  echo "Error: You need at least a message." >&2
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
  echo "Error: Too many arguments." >&2
  exit 1
  ;;
esac

if [[ -n "$CUSTOM_TOPIC" ]]; then
  TOPIC="$CUSTOM_TOPIC"
fi

if [[ -z "$TOPIC" ]]; then
  echo "Error: No topic configured. Set DEFAULT_TOPIC or provide --topic=NAME." >&2
  exit 1
fi

if [[ -z "$SERVER" ]]; then
  echo "Error: SERVER is not configured." >&2
  exit 1
fi

if [[ -z "$TOKEN" ]]; then
  echo "Error: TOKEN is not configured." >&2
  exit 1
fi

CURL_HEADERS=()

if [[ -n "$TITLE" ]]; then
  CURL_HEADERS+=(-H "Title: $TITLE")
fi

if [[ -n "$PRIORITY" ]]; then
  CURL_HEADERS+=(-H "X-Priority: $PRIORITY")
fi

if [[ -n "$TAGS" ]]; then
  CURL_HEADERS+=(-H "X-Tags: $TAGS")
fi

printf "%s" "$MESSAGE" | curl --fail --silent --show-error "${CURL_HEADERS[@]}" \
  -H "Authorization: Bearer $TOKEN" \
  --data-binary @- \
  "$SERVER/$TOPIC"

exit $?
