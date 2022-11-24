#!/bin/bash

set -eu

TIMESTAMP=$(date --iso-8601=seconds)

echo "🏃‍♀️ Starting backup of ${S3_PREFIX} (${TIMESTAMP})"
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
echo "🗜️ Compressing backup"
bzip2 -9 "${BACKUP_FILE}"
BACKUP_FILE="${BACKUP_FILE}.bz2"

echo
echo "🔐 Running mcrypt"
mcrypt "${BACKUP_FILE}" -k "${ENCRYPTION_KEY}"
BACKUP_FILE="${BACKUP_FILE}.nc"

echo
echo "⚖️ How big is it?"
du -sh "${BACKUP_FILE}"

echo
echo "🧮 Calculate hash"
BACKUP_FILE_MD5_BASE64="$(openssl md5 -binary ${BACKUP_FILE} | base64)"

echo "🪣 Uploading to bucket"
aws s3api put-object \
    --bucket="${BUCKET_NAME}" \
    --region="${BUCKET_REGION}" \
    --key="${S3_PREFIX}/${TIMESTAMP}.pgdump.bz2.nc" \
    --acl=bucket-owner-full-control \
    --body="${BACKUP_FILE}" \
    --content-md5="${BACKUP_FILE_MD5_BASE64}"
