# Multi-tenant Database Migration Script Documentation

## Overview

The `migrate-tenants.ts` script is a powerful tool designed to manage database migrations across multiple schemas in a PostgreSQL database. It supports various operations including migration creation, application, status checking, and database reset.

## Prerequisites

- Node.js and npm installed
- PostgreSQL database
- Prisma CLI installed (`npm install -g prisma`)
- Required environment variables set in `.env` file:
  ```env
  DATABASE_URL="postgresql://username:password@host:port/database"
  ```

## Commands

### 1. Check Migration Status
```bash
npx ts-node scripts/migrate-tenants.ts status
```
Shows the current state of all schemas and their migration versions.

**Output includes:**
- List of all schemas
- Current version of each schema
- Last applied migration
- Migration timestamp
- Pending changes (if any)

### 2. Create and Apply Migration
```bash
npx ts-node scripts/migrate-tenants.ts migrate <migration-name>
```
Creates and applies a new migration across all schemas.

**Options:**
- `--dry-run`: Preview changes without applying them
- `--skip-backup`: Skip creating backups (not recommended)
- `--schema <name>`: Target a specific schema
- `--force`: Skip confirmations

**Example:**
```bash
npx ts-node scripts/migrate-tenants.ts migrate add_user_table
```

### 3. Reset Database
```bash
npx ts-node scripts/migrate-tenants.ts reset
```
Completely resets the database by dropping all tables in all schemas.

**⚠️ WARNING: This is a destructive operation that will delete all data!**

**Options:**
- `--force`: Skip confirmation prompt

### 4. Sync Schemas
```bash
npx ts-node scripts/migrate-tenants.ts sync
```
Synchronizes all schemas with the current schema structure.

### 5. Rollback Migration
```bash
npx ts-node scripts/migrate-tenants.ts rollback <migration-name> --schema <schema-name>
```
Rolls back a specific migration for a given schema.

**Required options:**
- `--schema <name>`: Specify the target schema

## Schema Organization

The script expects Prisma schema files to be organized in the following structure:
```
prisma/
  schema/
    schema.prisma       # Main schema file with generator and datasource
    user.prisma        # User-related models
    product.prisma     # Product-related models
    ...                # Other domain-specific schema files
```

## Error Handling

The script includes robust error handling:
1. Database connection verification
2. Disk space checks
3. Permission validation
4. Migration lock mechanism to prevent concurrent migrations
5. Automatic cleanup of temporary files
6. Detailed error logging

## Best Practices

1. **Always backup before migrating:**
   ```bash
   npx ts-node scripts/migrate-tenants.ts migrate <name> --dry-run
   ```
   Review the changes before applying them.

2. **Use descriptive migration names:**
   ```bash
   # Good
   npx ts-node scripts/migrate-tenants.ts migrate add_user_authentication
   
   # Bad
   npx ts-node scripts/migrate-tenants.ts migrate update1
   ```

3. **Check status regularly:**
   ```bash
   npx ts-node scripts/migrate-tenants.ts status
   ```
   Monitor the state of your schemas.

4. **Target specific schemas when possible:**
   ```bash
   npx ts-node scripts/migrate-tenants.ts migrate <name> --schema tenant1
   ```
   This reduces the risk of unintended changes.

## Troubleshooting

### Common Issues

1. **Migration Lock Error**
   ```
   Could not acquire migration lock. Aborting.
   ```
   Solution: Check if another migration is running or manually release the lock by resetting.

2. **Permission Denied**
   ```
   Error: permission denied for schema "public"
   ```
   Solution: Ensure your database user has sufficient permissions.

3. **Schema Not Found**
   ```
   Error: schema "tenant1" does not exist
   ```
   Solution: Verify schema name and check database connection.

### Recovery Steps

1. If a migration fails:
   ```bash
   # Check status
   npx ts-node scripts/migrate-tenants.ts status
   
   # Rollback if needed
   npx ts-node scripts/migrate-tenants.ts rollback <failed-migration> --schema <schema-name>
   ```

2. For corrupted schemas:
   ```bash
   # Reset specific schema
   npx ts-node scripts/migrate-tenants.ts reset --schema <schema-name>
   
   # Reapply migrations
   npx ts-node scripts/migrate-tenants.ts migrate <migration-name> --schema <schema-name>
   ```

## Security Considerations

1. Always use environment variables for sensitive information
2. Regularly rotate database credentials
3. Backup data before major migrations
4. Use `--dry-run` to preview changes
5. Implement proper access controls

## Support

For issues and feature requests, please:
1. Check the error logs
2. Review this documentation
3. Submit detailed bug reports with:
   - Command used
   - Error message
   - Schema state (from status command)
   - Environment details 