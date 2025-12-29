#!/bin/bash
# Database Restore Script
# File: deployment/scripts/restore-database.sh
# Usage: ./restore-database.sh <backup_file.sql.gz>

set -e

# Configuration
DB_NAME="${DB_NAME:-devops_dashboard}"
DB_USER="${DB_USER:-devops_user}"
DB_HOST="${DB_HOST:-localhost}"
BACKUP_FILE="$1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Validate input
if [ -z "$BACKUP_FILE" ]; then
    error "Usage: $0 <backup_file.sql.gz>"
fi

# Check if file exists (local or S3)
if [[ "$BACKUP_FILE" == s3://* ]]; then
    log "Downloading backup from S3..."
    LOCAL_FILE="/tmp/$(basename $BACKUP_FILE)"
    aws s3 cp "$BACKUP_FILE" "$LOCAL_FILE"
    BACKUP_FILE="$LOCAL_FILE"
fi

if [ ! -f "$BACKUP_FILE" ]; then
    error "Backup file not found: $BACKUP_FILE"
fi

# Verify file integrity
log "Verifying backup file integrity..."
if ! gzip -t "$BACKUP_FILE"; then
    error "Backup file is corrupted"
fi

# Confirmation
echo ""
echo "=========================================="
echo "  DATABASE RESTORE"
echo "=========================================="
echo "  Database:    $DB_NAME"
echo "  Host:        $DB_HOST"
echo "  Backup:      $BACKUP_FILE"
echo "=========================================="
echo ""
warning "This will DROP and recreate the database!"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    log "Restore cancelled"
    exit 0
fi

# Create backup of current database before restore
log "Creating backup of current database before restore..."
CURRENT_BACKUP="/tmp/${DB_NAME}_pre_restore_$(date +%Y%m%d_%H%M%S).sql.gz"
PGPASSWORD="${DB_PASSWORD}" pg_dump -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" 2>/dev/null | gzip > "$CURRENT_BACKUP" || true
if [ -s "$CURRENT_BACKUP" ]; then
    log "Pre-restore backup saved: $CURRENT_BACKUP"
else
    warning "Could not create pre-restore backup (database might be empty)"
fi

# Terminate existing connections
log "Terminating existing database connections..."
PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '${DB_NAME}'
  AND pid <> pg_backend_pid();
" 2>/dev/null || true

# Drop and recreate database
log "Dropping existing database..."
PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "DROP DATABASE IF EXISTS ${DB_NAME};"

log "Creating fresh database..."
PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "CREATE DATABASE ${DB_NAME};"

# Restore from backup
log "Restoring database from backup..."
if gunzip -c "$BACKUP_FILE" | PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME"; then
    log "Database restored successfully!"
else
    error "Failed to restore database"
fi

# Verify restore
log "Verifying restore..."
TABLE_COUNT=$(PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';")
log "Tables restored: $TABLE_COUNT"

echo ""
echo "=========================================="
echo "  RESTORE COMPLETED"
echo "=========================================="
echo "  Database:       $DB_NAME"
echo "  Tables:         $TABLE_COUNT"
echo "  Pre-restore:    $CURRENT_BACKUP"
echo "=========================================="
