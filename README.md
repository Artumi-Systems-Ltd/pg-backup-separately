### `pg-backup-separately` README

---

## `pg-backup-separately`

This package provides two Bash scripts for PostgreSQL database management:

1. **Backup Script**: Backs up each PostgreSQL database individually along with user roles/permissions.
2. **Restore Script**: Restores each PostgreSQL database from the backup and applies saved user roles/permissions.
3. **Check Env**: This script checks that your env file has the correct contents.

The idea here is that we can backup all the databases on a cluster as
separate files, including the cluster's config files and then restore
them to a new cluster, optionally filtering out any particular
database.

The database backups will be .dump files produced by pg_dump with the
`-F c` flag, that is the single file that represents the database.

The restore script won't run if it looks like the cluster isn't empty.


---

### Features

- **Backup each database separately** using PostgreSQL's `pg_dump` with the `-F c` (custom format) option.
- **Backup user permissions** using `pg_dumpall --roles-only`.
- **Restore databases and user roles** from individual backup files.
- **Secure environment configuration**: Settings are stored in a `.env` file, with strict permissions (`chmod 600`).
- **Permission checks**: Ensures `.env` file has the correct security permissions before running.
- **Customizable Paths**: Automatically update paths in the `postgresql.conf` file based on environment variables.
- **Filtering**: Optionally filter databases during restore operations to skip databases that do not match a specified pattern.

---

### Requirements

- PostgreSQL installed on your system.
- A PostgreSQL user with privileges to access and back up all databases.
- Bash shell (Linux or macOS).

---

### Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/artumi-systems-ltd/pg-backup-separately.git
   cd pg-backup-separately
   ```

2. **Create a `.env` file** in the root directory of the project:

   ```bash
   touch mycluster.env
   ```

3. **Edit the `mycluster.env` file** with your PostgreSQL settings:

   ```bash
   PGUSER=your_pg_user
   PGPASSWORD=your_pg_password
   PGHOST=localhost
   PGPORT=5432
   BACKUP_DIR=/path/to/backup
   ```

4. **Secure the `mycluster.env` file** by setting the correct permissions:

   ```bash
   chmod 600 .env
   ```

---

### Usage

#### 1. **Backup Script**

The backup script will:
- Backup all PostgreSQL databases (except templates) to individual files in the specified `BACKUP_DIR`.
- Backup user roles and permissions.

To run the backup script:

```bash
./pg_backup.sh mycluster.env
```

#### 2. **Restore Script**

The restore script will, in this order:
- Restore user roles and permissions.
- Restore the postgresql configuration
- Restore all databases from individual backup files, unless there is
  a filter option.

To run the restore script:

```bash
./pg_restore.sh mycluster.env
```

Note that the cluster you save to can be different to that you backed
up from, but there will be limitations from the pg_dump command that
does the real work that you should know about.


---

### `.env` File Configuration

The `.env` file stores the necessary PostgreSQL settings used by the scripts:

- `PGUSER`: The PostgreSQL user with access to all databases.
- `PGPASSWORD`: The password for the PostgreSQL user.
- `PGHOST`: The PostgreSQL host (typically `localhost` for local setups).
- `PGPORT`: The PostgreSQL port (usually `5432`).
- `BACKUP_DIR`: The directory where backup files will be stored. Ensure this directory exists or is created by the script.

#### Example `.env`:

```bash
PGUSER=admin
PGPASSWORD=your_secure_password
PGHOST=localhost
PGPORT=5432
BACKUP_DIR=/var/backups/postgres
```

---

### File Permission Check

To ensure security, the backup script checks that the `.env` file has the correct permissions (`chmod 600`). If the permissions are incorrect, it will show an error and explain how to fix it:

```bash
.env file has incorrect permissions (755).
Please set the correct permissions using the following command:
chmod 600 .env
```

---

### Backup and Restore Details

- **Database Backups**: Each PostgreSQL database will be backed up to a `.dump` file using the custom format (`-F c`).
- **User Permissions**: The `pg_dumpall --roles-only` command will export user roles/permissions to a SQL file.
- **Restore Process**: Each `.dump` file is restored individually. The user permissions are applied from the SQL file.

---

### Notes

- Make sure the PostgreSQL user has the required privileges to access and back up all databases and roles.
- Test the scripts in a safe environment before using them in production.
- Keep your `.env` file secure and never commit it to version control.

---

### License

This project is licensed under the MIT License.

---

### Contribution

Feel free to open issues or submit pull requests to enhance the functionality of the scripts. We welcome contributions from the community.

---

### Support

For any questions or support, please contact us at [support@artumi-systems.com](mailto:support@artumi-systems.com).

---

This package was developed by **Artumi Systems Ltd**.
