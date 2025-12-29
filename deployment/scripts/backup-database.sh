#!/bin/bash
# Database Backup Script
# File: deployment/scripts/backup-database.sh
# Usage: ./backup-database.sh [daily|weekly|monthly]

set -e

# Configuration
DB_NAME="${DB_NAME:-devops_dashboard}"
DB_USER="${DB_USER:-devops_user}"
DB_HOST="${DB_HOST:-localhost}"
BACKUP_DIR="/var/backups/postgresql"
S3_BUCKET="${S3_BUCKET:-your-backup-bucket}"
RETENTION_DAYS=7
BACKUP_TYPE="${1:-daily}"

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${BACKUP_TYPE}_${TIMESTAMP}.sql.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Create backup directory if not exists
mkdir -p "$BACKUP_DIR"

log "Starting ${BACKUP_TYPE} backup of database: ${DB_NAME}"

# Create backup
log "Creating backup..."
if PGPASSWORD="${DB_PASSWORD}" pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" | gzip > "$BACKUP_FILE"; then
    log "Backup created: $BACKUP_FILE"
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "Backup size: $BACKUP_SIZE"
else
    error "Failed to create backup"
    exit 1
fi

# Verify backup integrity
log "Verifying backup integrity..."
if gzip -t "$BACKUP_FILE"; then
    log "Backup integrity verified"
else
    error "Backup file is corrupted"
    exit 1
fi

# Upload to S3 (if configured)
if [ -n "$S3_BUCKET" ] && [ "$S3_BUCKET" != "your-backup-bucket" ]; then
    log "Uploading to S3: s3://${S3_BUCKET}/backups/${BACKUP_TYPE}/"
    if aws s3 cp "$BACKUP_FILE" "s3://${S3_BUCKET}/backups/${BACKUP_TYPE}/" --storage-class STANDARD_IA; then
        log "Upload to S3 completed"
    else
        warning "Failed to upload to S3"
    fi
else
    warning "S3 bucket not configured, skipping upload"
fi

# Cleanup old local backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
REMAINING_BACKUPS=$(find "$BACKUP_DIR" -name "*.sql.gz" -type f | wc -l)
log "Remaining local backups: $REMAINING_BACKUPS"

# Cleanup old S3 backups (if configured)
if [ -n "$S3_BUCKET" ] && [ "$S3_BUCKET" != "your-backup-bucket" ]; then
    log "Cleaning up old S3 backups..."
    # Note: Consider using S3 lifecycle policies instead
    aws s3 ls "s3://${S3_BUCKET}/backups/${BACKUP_TYPE}/" | while read -r line; do
        FILE_DATE=$(echo "$line" | awk '{print $1}')
        FILE_NAME=$(echo "$line" | awk '{print $4}')
        if [ -n "$FILE_NAME" ]; then
            FILE_AGE=$(( ($(date +%s) - $(date -d "$FILE_DATE" +%s)) / 86400 ))
            if [ "$FILE_AGE" -gt "$RETENTION_DAYS" ]; then
                aws s3 rm "s3://${S3_BUCKET}/backups/${BACKUP_TYPE}/${FILE_NAME}"
                log "Deleted old S3 backup: $FILE_NAME"
            fi
        fi
    done
fi

log "Backup completed successfully!"

# Summary
echo ""
echo "=========================================="
echo "  BACKUP SUMMARY"
echo "=========================================="
echo "  Database:    $DB_NAME"
echo "  Type:        $BACKUP_TYPE"
echo "  File:        $BACKUP_FILE"
echo "  Size:        $BACKUP_SIZE"
echo "  Timestamp:   $TIMESTAMP"
echo "=========================================="
