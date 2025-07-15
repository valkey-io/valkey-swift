#!/bin/bash
set -eux

get_valkey()
{
    DESTINATION_FOLDER=$1
    COMMANDS_ADDRESS=$2
    COMMANDS_VERSION=${3:-""}

    # clone valkey into folder
    git clone --depth 1 "$COMMANDS_ADDRESS" "$DESTINATION_FOLDER"

    pushd "$DESTINATION_FOLDER"

    git fetch --tags --depth 1

    if [ -z "$COMMANDS_VERSION" ]; then
        RELEASE_REVISION=$(git rev-list --tags --max-count=1)
        if [ -n "$RELEASE_REVISION" ]; then
            echo "Describe $RELEASE_REVISION"
            COMMANDS_VERSION=$(git describe --tags "$RELEASE_REVISION")
        else
            COMMANDS_VERSION=$(git rev-parse HEAD)
        fi
    fi
    echo "Get version $COMMANDS_VERSION"
    git checkout "$COMMANDS_VERSION"

    popd
}

cleanup()
{
    if [ -n "$TEMP_DIR" ]; then
        echo "Cleanup $TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
}

COMMANDS_LOCATION=${1:-"https://github.com/valkey-io/valkey.git"}

while getopts ':f:v:' option
do
    case $option in
        v) 
            COMMANDS_VERSION=$OPTARG ;;
        f) 
            COMMANDS_FOLDER=$OPTARG ;;
        ?) 
            echo "Usage: update-commands-json.sh [-v VERSION] [-f FOLDER] LOCATION"
            exit 1 ;;
    esac
done
shift "$((OPTIND -1))"
COMMANDS_LOCATION=${1:-"https://github.com/valkey-io/valkey.git"}
COMMANDS_VERSION=${COMMANDS_VERSION:-""}
COMMANDS_FOLDER=${COMMANDS_FOLDER:-"src/commands/"}

FILENAME=$(basename "$COMMANDS_LOCATION" .git)

if [[ "$COMMANDS_LOCATION" == http* ]]; then
    TEMP_DIR=$(mktemp -d)
    trap cleanup EXIT $?

    get_valkey "$TEMP_DIR" "$COMMANDS_LOCATION" "$COMMANDS_VERSION"
    COMMANDS_LOCATION=$TEMP_DIR
fi

jq -s 'reduce .[] as $item (
    {}; . * {
        ((if ($item | flatten | first | .container) == null then "" else ($item | flatten | first | .container) + " " end) + ($item | keys | first)):
        ($item | flatten | first | map_values(.))
    }
)' \
"$COMMANDS_LOCATION/$COMMANDS_FOLDER"*.json > Sources/_ValkeyCommandsBuilder/Resources/"$FILENAME"-commands.json
