#!/bin/bash

set -eu

TIMESTAMP=$(date --iso-8601=seconds)

if [[ "${S3_PREFIX}" != */ ]]
then
    S3_PREFIX="${S3_PREFIX}/"
fi

if [[ "${S3_PREFIX}" = "/" ]]
then
    S3_PREFIX=""
fi

echo "🏃‍♀️ Starting backup for S3_PREFIX=\"${S3_PREFIX}\" (${TIMESTAMP})"
echo

echo "🪪 AWS caller identity:"
aws sts get-caller-identity
echo

BACKUP_FILE="db.pg_dump.bin"

echo "💩 Running pg_dump"

pg_dump \
    --blobs \
    --format=custom \
    --file="${BACKUP_FILE}" \
    --verbose

echo
echo "🔐 Running mcrypt"
mcrypt "${BACKUP_FILE}" -k "${ENCRYPTION_KEY}"
BACKUP_FILE="${BACKUP_FILE}.nc"

echo
echo "⚖️ How big is it?"
du -sh "${BACKUP_FILE}"

echo "🪣 Uploading to bucket"
aws s3 cp \
    --region="${BUCKET_REGION}" \
    --acl=bucket-owner-full-control \
    "${BACKUP_FILE}" \
    "s3://${BUCKET_NAME}/${S3_PREFIX}${TIMESTAMP}.pgdump.nc"
