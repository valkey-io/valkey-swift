#!/bin/bash

get_valkey()
{
    DESTIONATION_FOLDER=$1
    # clone valkey into folder
    git clone --depth 1 https://github.com/valkey-io/valkey.git "$DESTIONATION_FOLDER"

    pushd "$DESTIONATION_FOLDER"

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

VALKEY_LOCATION=${1:-""}

if [ -z "$VALKEY_LOCATION" ]; then
    TEMP_DIR=$(mktemp -d)
    trap cleanup EXIT $?

    get_valkey $TEMP_DIR
    VALKEY_LOCATION=$TEMP_DIR
fi

jq -s 'reduce .[] as $item (
    {}; . * {
        ((if ($item | flatten | first | .container) == null then "" else ($item | flatten | first | .container) + " " end) + ($item | keys | first)):
        ($item | flatten | first | map_values(.))
    }
)' \
"$VALKEY_LOCATION"/src/commands/*.json > Sources/ValkeyCommandsBuilder/Resources/commands.json
