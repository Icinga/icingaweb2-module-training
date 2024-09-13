# Database Migration Hook

Icinga Web 2.12 provides a `DbMigrationHook` Hook that can be used to automatically perform database migrations.

What are database migrations? Migrations are used to modify the structure of the database over time.
For example when we want to add new tables or columns to tables, we would create a migration to perform these
actions on the existing database schema.

## Database Schema

During the initial installation of an Icinga Web module, we need to initialize the database we want to use
for the module.

This is usually done by providing schema files for the supported database systems (e.g. MySQL, PostgreSQL, etc.).
For this we create a directory `schema` and the corresponding files:

```
mkdir schema/

touch schema/mysql.schema.sql
touch schema/pgsql.schema.sql
```

These files contain all instructions that are required to bootstrap the database:

```
vi schema/mysql.schema.sql

CREATE TABLE asset (
  id int unsigned NOT NULL AUTO_INCREMENT,
  user_id int NULL,
  serial_no varchar(50) NOT NULL,
  PRIMARY KEY(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

CREATE TABLE training_schema (
  id int unsigned NOT NULL AUTO_INCREMENT,
  version varchar(64) NOT NULL,
  timestamp bigint unsigned NOT NULL,
  success enum ('n', 'y') DEFAULT NULL,
  reason text DEFAULT NULL,

  PRIMARY KEY (id),
  CONSTRAINT idx_training_schema_version UNIQUE (version)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

INSERT INTO training_schema (version, timestamp, success)
  VALUES ('1.0.0', UNIX_TIMESTAMP() * 1000, 'y');
```

Users of the module can now create and initialize the database:

```
CREATE DATABASE training;
mysql training < /usr/share/icingaweb2/modules/training/schema/mysql.schema.sql
```

The table `training_schema` is used to track the migrations.
Each migration will generate a row in this table to determine the state of the schema:

```
mysql> SELECT * FROM training_schema;
+----+---------+---------------+---------+--------+
| id | version | timestamp     | success | reason |
+----+---------+---------------+---------+--------+
|  1 | 1.0.0   | 1714488742000 | y       | NULL   |
+----+---------+---------------+---------+--------+
```

A migration could for example, add new tables, add new columns on tables or update existing columns.

In the following section we will create a migration to update the `asset` table.

## Database Migrations

In order to use the database migration hook it's required to place the migrations scripts in the following directories:

```
mkdir schema/mysql-upgrades/
mkdir schema/pgsql-upgrades/
```

The name of these files should be the version of the migration (e.g. `1.0.0.sql`, `1.1.0.sql`).

Now we can create SQL files that update the existing schema.
For example, we can adjust the length of the `serial_no` field:

```
vi schema/mysql-upgrades/1.1.0.sql
ALTER TABLE asset MODIFY COLUMN serial_no varchar(128) NOT NULL;

INSERT INTO training_schema (version, timestamp, success)
  VALUES ('1.1.0', UNIX_TIMESTAMP() * 1000, 'y');
```

Each migration will also insert itself into the table that tracks the migrations.

Every time we require an update to the database schema, we create a new migration file with a higher version.

```
ls -l  schema/mysql-upgrades/
1.0.0.sql
1.1.0.sql
1.2.0.sql
1.3.0.sql
```

Now we need to implement the `DbMigrationHook` Hook.

First, we need to create a Model for the `training_schema` rows so that we can interact with the
table in an object-oriented way.

```php
vi library/Training/Model/Schema.php

<?php

namespace Icinga\Module\Training\Model;

use DateTime;
use ipl\Orm\Behavior\BoolCast;
use ipl\Orm\Behavior\MillisecondTimestamp;
use ipl\Orm\Behaviors;
use ipl\Orm\Model;

/**
 * A database model for Training schema version table
 *
 * @property int $id Unique identifier of the database schema entries
 * @property string $version The current schema version of the module
 * @property DateTime $timestamp The insert/modify time of the schema entry
 * @property bool $success Whether the database migration of the current version was successful
 * @property ?string $reason The reason why the database migration has failed
 */
class Schema extends Model
{
    public function getTableName(): string
    {
        return 'training_schema';
    }

    public function getKeyName()
    {
        return 'id';
    }

    public function getColumns(): array
    {
        return [
            'version',
            'timestamp',
            'success',
            'reason'
        ];
    }

    public function createBehaviors(Behaviors $behaviors): void
    {
        $behaviors->add(new BoolCast(['success']));
        $behaviors->add(new MillisecondTimestamp(['timestamp']));
    }
}
```

Second, we create the Hook at `ProvidedHook/DbMigration.php`. This class will implement the abstract `DbMigrationHook`.


```php
vi library/Training/ProvidedHook/DbMigration.php

<?php

namespace Icinga\Module\Training\ProvidedHook;

use Icinga\Module\Training\Common\Database;
use Icinga\Module\Training\Model\Schema;

use Icinga\Application\Hook\DbMigrationHook;
use ipl\Orm\Query;
use ipl\Sql\Connection;

class DbMigration extends DbMigrationHook
{
    use Database {
        getDB as private getTrainingDb;
    }

    /**
     * Returns a database connection that is used to apply the migration
     */
    public function getDb(): Connection
    {
        return $this->getTrainingDb();
    }

    /**
     * Returns a name that is shown in the Web UI
     */
    public function getName(): string
    {
        return $this->translate('Training');
    }

    /**
     * Returns descriptions for migration to show in the Web UI
     */
    public function providedDescriptions(): array
    {
        return [
            '1.1.0' => $this->translate('Updates the serial number length'),
        ];
    }

    /**
     * Returns the Model for the schema table
     */
    protected function getSchemaQuery(): Query
    {
        return Schema::on($this->getDb());
    }

    /**
     * getVersion tries to determine the current schema version
     */
    public function getVersion(): string
    {
        if ($this->version === null) {
            $conn = $this->getDb();
            $schema = $this->getSchemaQuery()
                ->columns(['version', 'success'])
                ->orderBy('id', SORT_DESC)
                ->limit(2);

            if (static::tableExists($conn, $schema->getModel()->getTableName())) {
                /** @var Schema $version */
                foreach ($schema as $version) {
                    if ($version->success) {
                        $this->version = $version->version;

                        break;
                    }
                }

                if (! $this->version) {
                    // Schema version table exist
                    $this->version = '1.0.0';
                }
            } elseif (static::getColumnType($conn, 'asset', 'serial_no') === 'varchar(128)') {
                // Upgrade script 1.1.0 alters the asset.serial_no column from `varchar(50)` -> `varchar(128)`.
                // Therefore, we can safely use this as the last migrated version.
                $this->version = '1.1.0';
        }

        return $this->version;
    }
}
```

Finally, we register the Hook in the module's `run.php`

```
vi run.php

$this->provideHook('DbMigration', '\\Icinga\\Module\\Training\\ProvidedHook\\DbMigration');
```

Now we can use the Icinga Web migrations page to apply the module's migrations.
