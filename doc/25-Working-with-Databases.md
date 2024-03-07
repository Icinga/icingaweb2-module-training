# IPL and Databases

Icinga Web module work very commonly databases, either to store their own data or to read data from other modules.
This is why the IPL provides two libraries to work with databases.

# ipl-sql

`ipl-sql` provides an SQL abstraction layer that builds on top of PHP's PDO.
It provides an object-oriented way to access databases.

## Database Connection

A core feature of the library is the `Connection` class.
It simplifies working with different database types.

We have already seen this in the `sqlite` example:

```php
use ipl\Sql\Connection;

$connection = new Connection([
  'db'     => 'sqlite',
  'dbname' => 'assets.sqlite'
]);
```

This works similar for a full MySQL connection with authentication and transport encryption:

```php
$connection = new Connection([
    'db'         => 'mysql',
    'host'       => '192.0.1.11',
    'port'       => '3306',
    'dbname'     => 'assets',
    'username'   => 'dbuser',
    'password'   => 'password123',
    'charset'    => 'utf8',
    'attributes' => [
        PDO::MYSQL_ATTR_SSL_CA   => '/etc/myapp/mysql/ca.pem',
        PDO::MYSQL_ATTR_SSL_CERT => '/etc/myapp/mysql/cert.pem',
        PDO::MYSQL_ATTR_SSL_KEY  => '/etc/myapp/mysql/key.pem'
    ]
]);
```

Once we have created a connection we can explicitly connect and disconnected. This is optional however.

```php
// Optional
$connection->connect();
$connection->disconnect();
```

We can also check if the connection to the database is still available:

```
// Returns true or false
$connection->ping();
```

## Database Configuration

The `Config` class holds information like the host, port and username. It provides a simple way to configure a database connection.

A new `Config` object is initialized with key-value pairs containing the configuration (`["host"->"localhost", "port"->"3306"]`).
This means, we can simply pass a module's configuration to create a SQL configuration:

```php
use Icinga\Data\ResourceFactory;

use Icinga\Application\Config as AppConfig;
use ipl\Sql\Config as SqlConfig;

use ipl\Sql\Connection

// Creates a new database configuration from the module's configuration
$config = new SqlConfig(ResourceFactory::getResourceConfig(
    AppConfig::module('notifications')->get('database', 'resource', 'my-database')
));

// Creates a new connection from the database configuration
$connection = new Connection($config);
```

## SQL Statements

After we have configured and established a connection, it can be used to execute SQL statements.
The following examples will use the Asset database from the previous section.

A simple example would be:

```php
// Load a single column or row
$connection->fetchCol('SELECT serial_no from asset');
$connection->fetchRow('SELECT serial_no from asset');

// Load everything
$connection->fetchAll('SELECT * from asset');

// Prepare a statement for execution
$q = $connection->prepexec('SELECT * from asset WHERE serial_no = ?', ['SDFOIJSDFS']);
$q->fetch();
```

All of the above are also available as PHP Generators:

```php
$connection->yieldAll('SELECT * from asset');
```

The connection also provides functions for these SQL statements:

```php
$data = ['id': 123, 'name': 'jon snow'];

$connection->insert('my_table', $data);

$data = ['name': 'jon doe'];

$connection->update('my_table', $data, ['id = ?' => '123']);

$connection->delete('my_table',
  ['id = ?' => '123']);
```

However, a more object-oriented way is also possible. There are several classes provided by `ipl-sql` that correspond to their SQL statements:

```php
use ipl\Sql\Delete;
use ipl\Sql\Insert;
use ipl\Sql\Select;
use ipl\Sql\Update;
```

These allow us to create SQL statements as objects and pass them to the connection:

```php
$q = (new Select())
  ->columns(['manufacturer', 'serial_no'])
  ->from('asset')

$connection->select($q);
```

These classes also provide the SQL clauses (`WHERE`, `ORDER BY`, etc.) as functions:

```php
$q = (new Select())
      ->distinct()
      ->columns(['c.id', 'c.name', 'orders' => 'COUNT(o.customer)'])
      ->from('customer c')
      ->joinLeft(
          'order o',
          ['o.customer = c.id', 'o.state = ?' => 'resolved']
      )
      ->where(['c.name LIKE ?' => '%Doe%'])
      ->groupBy(['c.id'])
      ->having(['COUNT(o.customer) >= ?' => 42])
      ->orderBy(['COUNT(o.customer)', 'c.name'])
      ->offset(75)
      ->limit(25);
```

The `Insert`, `Update` and `Delete` classes are used in a similar way:

```php
// Insert Statement
$i = (new Insert())
    ->into('asset')
    ->values([
        'id' => 7,
        'user_id' => 1,
        'serial_no' => 'SDFOIA341',
        'manufacturer' => 'hp',
        'type' => 'screen',
    ]);

$connection->prepexec($i);

// Update Statement
$u = (new Update())
   ->table('asset')
   ->set(['user_id' => 2])
   ->where(['id = ?' => 7]);

$connection->prepexec($u);

// Delete Statement
$d = (new Delete())
   ->from('asset')
   ->where(['id = ?' => 7])

$connection->prepexec($d);
```

However, instead of interacting with tables via a query language, what we really want is to use an object–relational mapping (ORM).

# ipl-orm

The `ipl-orm` library provides a translation between PHP objects and relational SQL tables.

Like other ORM frameworks, it allows us to define objects to interact with the content of the database.
Each database table has a corresponding "Model" which is used to interact with that table.

## Model

We have already seen the User and Asset Models in the previous section.

```php
<?php

namespace Icinga\Module\Training\Model;

use ipl\Orm\Model;

class User extends Model
{
    // The name of the table this Model belongs to
    public function getTableName()
    {
        return 'user';
    }

    // The table's key
    public function getKeyName()
    {
        return 'id';
    }

    // The list of columns that should be returned from the table
    public function getColumns()
    {
        return ['name'];
    }
}
```

After a Model is defined, we can use a database connection to translate our table into objects.

```php
use ipl\Sql\Connection;
use ipl\Orm\Model;

$conn = new Connection([
  'db' => 'sqlite',
]);

$users = User::on($conn)->execute();
```

## Relations

Instead of handcrafting SQL joins, the `ipl-orm` library provides `Relations` that can be established between models.

We have already seen this in the Asset model, which belongs to a User.
By setting the `createRelations` method we can define these relationships.

```php
use ipl\Orm\Model;
use ipl\Orm\Relations;

class Asset extends Model
{
  public function createRelations(Relations $relations)
  {
    $relations->belongsTo('user', User::class);
  }
}
```

Other possible relations are: `hasOne`, `belongsTo`, `belongsToMany`.

This is also where we would define joins between tables and if there are intermediate tables for many-to-many relationships.

```php
$relations->belongsToMany('product', Product::class)
    ->through('product_order');

$relations->hasMany('member', Member::class)
    ->setJoinType('LEFT');

$relations->belongsToMany('order', Order::class)
    ->through('order_customer')
    ->setJoinType('LEFT');

$relations->hasMany('customer', Customer::class)
    ->setCandidateKey('name')
    ->setForeignKey('user_name');
```

## Behaviors

Behaviors are a way to re-use functionality that is common across many models.
Conceptually they are similar to PHP traits.

For example, many models might use a timestamp field and the logic to manage these fields is not specific to any one model.

This is why the `ipl-orm` library includes a MillisecondTimestamp behaviors:


```php
public function createBehaviors(Behaviors $behaviors)
{
    // The 'created' field should be treated as a timestamp
    $behaviors->add(new MillisecondTimestamp([
        'created'
    ]));
}
```

A behavior will "hook" into the transaction from and to the database and transform the specified fields (i.e. parse a timestamp).

Other behaviors in the library are:

```php
// Unify boolean values to true and false
$behaviors->add(new BoolCast([
    'ready',
    'started'
]));

// Support hex filters for binary columns and
// PHP resource (in) / bytea hex format (out) transformation for PostgreSQL
$behaviors->add(new Binary([
    'id'
]));
```
