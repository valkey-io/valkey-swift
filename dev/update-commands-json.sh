#!/bin/bash

get_valkey()
{
    DESTINATION_FOLDER=$1
    COMMANDS_ADDRESS=$2

    # clone valkey into folder
    git clone --depth 1 "$COMMANDS_ADDRESS" "$DESTINATION_FOLDER"

    pushd "$DESTINATION_FOLDER"

    git fetch --tags
    RELEASE_REVISION=$(git rev-list --tags --max-count=1)
    if [ -n "$RELEASE_REVISION" ]; then
        echo "Describe $RELEASE_REVISION"
        BRANCH_NAME=$(git describe --tags "$RELEASE_REVISION")
    else
        BRANCH_NAME=$(git rev-parse HEAD)
    fi
    echo "Get version $BRANCH_NAME"
    git checkout "$BRANCH_NAME"

    popd
}

cleanup()
{
    if [ -n "$TEMP_DIR" ]; then
        echo "Cleanup $TEMP_DIR"
        rm -rf $TEMP_DIR
    fi
}

COMMANDS_LOCATION=${1:-"https://github.com/valkey-io/valkey.git"}
COMMANDS_FOLDER=${2:-"src/commands/"}

FILENAME=$(basename "$COMMANDS_LOCATION" .git)

if [[ "$COMMANDS_LOCATION" == http* ]]; then
    TEMP_DIR=$(mktemp -d)
    trap cleanup EXIT $?

    get_valkey $TEMP_DIR $COMMANDS_LOCATION
    COMMANDS_LOCATION=$TEMP_DIR
fi

jq -s 'reduce .[] as $item (
    {}; . * {
        ((if ($item | flatten | first | .container) == null then "" else ($item | flatten | first | .container) + " " end) + ($item | keys | first)):
        ($item | flatten | first | map_values(.))
    }
)' \
"$COMMANDS_LOCATION/$COMMANDS_FOLDER"*.json > Sources/ValkeyCommandsBuilder/Resources/"$FILENAME"-commands.json
