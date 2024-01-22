#!/bin/sh

set -x

# get parent folder to this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# get the parent of DIR
PARENT_DIR="$(dirname "$DIR")"

# set env vars
export BACKUP_NAME=test
export TARGET=/tmp/test-backup
export ENABLE_PRINT_FILES=true

# create test backup data
mkdir -p $TARGET
echo "test" > $TARGET/test.txt
echo "test" > $TARGET/test2.txt

# run dobackup.sh

docker run --rm \
    -e BACKUP_NAME \
    -e TARGET \
    -e S3_BUCKET_URL \
    -e S3_STORAGE_CLASS \
    -e S3_ENDPOINT \
    -e ENABLE_PRINT_FILES \
    -e WEBHOOK_URL \
    -v $TARGET:$TARGET \
    --entrypoint /dobackup.sh \
    --name s3-cron-backup \
    marmol/s3-cron-backup
