#!/bin/sh -e

# default storage class to standard if not provided
S3_STORAGE_CLASS=${S3_STORAGE_CLASS:-STANDARD}

# generate file name for tar
FILE_NAME=/tmp/$BACKUP_NAME-`date "+%Y-%m-%d_%H-%M-%S"`.tar.gz

# Check if TARGET variable is set
if [[ -z ${TARGET} ]];
then
    echo "TARGET env var is not set so we use the default value (/data)"
    TARGET=/data
else
    echo "TARGET env var is set"
fi

if [ -z "${S3_ENDPOINT}" ]; then
    AWS_ARGS=""
else
    #export AWS_IGNORE_CONFIGURED_ENDPOINT_URLS=false
	export AWS_ENDPOINT_URL_S3=${S3_ENDPOINT}
    AWS_ARGS="--endpoint-url ${S3_ENDPOINT}"
fi

# check if UPLOAD_WITHOUT_ARCHIVE

if [ -z "${UPLOAD_WITHOUT_ARCHIVE}" ] || [ "${UPLOAD_WITHOUT_ARCHIVE}" = "false" ]
then
    echo "UPLOAD_WITHOUT_ARCHIVE is not set or is set to false so we create an archive"
    # if the variable ENABLE_PRINT_FILES is equal to true then we print the files in the archive else we write in /dev/null
    if [ -z "${ENABLE_PRINT_FILES}" ] || [ "${ENABLE_PRINT_FILES}" = "false" ]
    then
        echo "creating archive (without printing files)"
        tar -zcvf $FILE_NAME $TARGET > /dev/null
    else
        echo "creating archive (with printing files)"
        tar -zcvf $FILE_NAME $TARGET
    fi
    
    echo "uploading archive to S3 [$FILE_NAME, storage class - $S3_STORAGE_CLASS]"
    aws s3 $AWS_ARGS cp --storage-class $S3_STORAGE_CLASS $FILE_NAME $S3_BUCKET_URL
    echo "removing local archive"
    rm $FILE_NAME
    echo "done"
else
    echo "UPLOAD_WITHOUT_ARCHIVE is set to true so we upload the files without creating an archive"
    echo "uploading files to S3 [$TARGET, storage class - $S3_STORAGE_CLASS]"

	# if UPLOAD_WITHOUT_ARCHIVE_CREATE_FOLDER_WITH_TIMESTAMP -> append timestamp to s3 bucket url
	if [ $UPLOAD_WITHOUT_ARCHIVE_CREATE_FOLDER_WITH_TIMESTAMP = "true" ]
	then
		S3_BUCKET_URL=$S3_BUCKET_URL/`date "+%Y-%m-%d_%H-%M-%S"`
		echo "UPLOAD_WITHOUT_ARCHIVE_CREATE_FOLDER_WITH_TIMESTAMP is set to true so we append timestamp to s3 bucket url"
		echo "new S3_BUCKET_URL: $S3_BUCKET_URL"
	fi

    # upload files to s3, keep existing files in s3
    # print files if ENABLE_PRINT_FILES is true
    if [ -z "${ENABLE_PRINT_FILES}" ] || [ "${ENABLE_PRINT_FILES}" = "false" ]
    then
        echo "uploading files (without printing files)"
        aws s3 $AWS_ARGS sync --storage-class $S3_STORAGE_CLASS $TARGET $S3_BUCKET_URL --quiet
    else
        echo "uploading files (with printing files)"
        aws s3 $AWS_ARGS sync --storage-class $S3_STORAGE_CLASS $TARGET $S3_BUCKET_URL
    fi
    echo "done"
fi


if [ -n "$WEBHOOK_URL" ]; then
    echo "notifying ${WEBHOOK_URL}"
    curl -m 10 --retry 5 $WEBHOOK_URL
fi
