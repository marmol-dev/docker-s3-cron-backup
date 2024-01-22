#!/bin/sh

# get parent folder to this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# get the parent of DIR
PARENT_DIR="$(dirname "$DIR")"

# set env vars
export BACKUP_NAME=test
export TARGET=/tmp/test-backup
export ENABLE_PRINT_FILES=true
export UPLOAD_WITHOUT_ARCHIVE=true
export UPLOAD_WITHOUT_ARCHIVE_CREATE_FOLDER_WITH_TIMESTAMP=true

# create test backup data
mkdir -p $TARGET
echo "test2" > $TARGET/test.txt
echo "test2" > $TARGET/test2.txt

# run dobackup.sh

docker run --rm \
    -e BACKUP_NAME \
    -e TARGET \
    -e S3_BUCKET_URL \
    -e S3_STORAGE_CLASS \
    -e S3_ENDPOINT \
    -e ENABLE_PRINT_FILES \
    -e WEBHOOK_URL \
    -e UPLOAD_WITHOUT_ARCHIVE \
    -e UPLOAD_WITHOUT_ARCHIVE_CREATE_FOLDER_WITH_TIMESTAMP \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_DEFAULT_REGION \
    -v $TARGET:$TARGET \
    -v $PARENT_DIR/dobackup.sh:/dobackup.sh \
    --entrypoint /dobackup.sh \
    --name s3-cron-backup \
    marmol/s3-cron-backup
