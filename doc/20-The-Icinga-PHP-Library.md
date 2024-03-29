# Digging Deeper – The Icinga PHP Library

The basic tutorial already covered how to create routes and views, as well as how to create your own library parts.
This tutorial will show you how to achieve the same (and more) by using the Icinga PHP Library (IPL). It also includes working with databases.

The [IPL](https://github.com/Icinga/icinga-php-library) is a bundle of multiple separate PHP libraries, each with a specific purpose:

* [ipl-html](https://github.com/Icinga/ipl-html)
  * This is a HTML abstraction layer. Essentially, it is the successor of what you already learned about view scripts. It lets you write HTML in an object oriented way
* [ipl-i18n](https://github.com/Icinga/ipl-i18n)
  * This bundles everything related to internationalisation
* [ipl-orm](https://github.com/Icinga/ipl-orm)
  * Icinga's object-relational mapper that makes working with your databases a breeze
* [ipl-sql](https://github.com/Icinga/ipl-sql)
  * A SQL abstraction layer. Builds on top of PHP's `PDO` and provides an object oriented way to access a database
* [ipl-stdlib](https://github.com/Icinga/ipl-stdlib)
  * Just a collection of various useful functions, classes and utilities
* [ipl-validator](https://github.com/Icinga/ipl-validator)
  * Provides common validators (email addresses, date-and-time, X.509 certificates, etc.)
* [ipl-web](https://github.com/Icinga/ipl-web)
  * It combines all other parts to provide useful widgets and base implementations for such. If you want to extend your views with controls such as the mighty `Search Bar` or maybe a `SortControl` and a `LimitControl`, this provides them.

**Prerequisites**:

You need at least Icinga Web version 2.9 and then you're good to go and can install them.

# Database Setup

This section will show how to interact with SQL databases using the `ipl-sql` and `ipl-orm` libraries.

For this, we need to prepare a database first. To keep it simple, this tutorial uses sqlite (you could also use a MySQL backend, but you'd have to adjust some of the connection examples then).

`sqlite3` is the command line tool for sqlite, let's install it:

```bash
apt install -y sqlite3
```

Now import the database schema shipped with this tutorial [here](res/asset-db.sql):

```bash
mkdir -p /etc/icingaweb2/modules/training/
cd /usr/share/icingaweb2/modules/training/

sqlite3 /etc/icingaweb2/modules/training/assets.sqlite < doc/res/asset-db.sql
```

This database now contains some users and several assets that belong to these users.

## Create a New Controller

We now want to display the asset data from the database in the web interface.
For this we create new controller named `AssetsController` in the usual place:

```bash
vim application/controllers/AssetsController.php
```

This controller will connect to the database using `ipl-sql`:

```php
<?php

namespace Icinga\Module\Training\Controllers;

use ipl\Sql\Connection;
use ipl\Web\Compat\CompatController;
use ipl\Web\Compat\SearchControls;

class AssetsController extends CompatController
{
    use SearchControls;

    /** @var Connection */
    protected $db;

    /**
     * Get the database connection
     *
     * @return Connection
     */
    protected function getDb()
    {
        if ($this->db === null) {
            $this->db = new Connection([
                'db' => 'sqlite',
                'dbname' => $this->Module()->getConfigDir() . '/assets.sqlite'
            ]);
        }

        return $this->db;
    }
}
```

Some notes regarding the example above:

* This controller extends a new class, the `CompatController`. It is provided by `ipl-web` and acts as a compatibility
  layer between Icinga Web and the IPL. Since the IPL could also be used outside of Icinga Web.
* It also uses a trait, `SearchControls`. This is also provided by `ipl-web` and implements initialization methods
  for the `SearchBar` and the `SearchEditor`, widgets we will use later on

`getDb()` returns the database connection to be used in various places. If you are not using sqlite, update this
according to your backend. The following additional configuration options might be useful:

  * `host`
  * `port`
  * `username`
  * `password`

# A Table of Assets

Now let's start with the actual implementation.

The goal is to display the assets from the database as a table.

The user should be able to filter, sort and limit the results. If there are more results than what fits on a
single page, the user should also be able to switch between pages.

## Setting up the ORM

But before we can display anything, we have to fetch it first, don't we? Let us prepare that by telling the object
relational mapper how our database looks like.

Though, before we start with this, let's take a look at the schema first. Without knowledge of that, we cannot
define (or rather, understand) the models. (The `*` suffix means it's required)

```
 ┌──────────────┐     ┌───────┐
 │ asset        │     │ user  │
 │──────────────│     │───────│
 │ id*          │  ┌─▶│ id*   │
 │ user_id      │──┘  │ name* │
 │ serial_no*   │     └───────┘
 │ manufacturer │
 │ type*        │
 └──────────────┘
```

Unless you are already familiar with this, you may wonder what the term `Model` means.

A `Model` is the representation of a database table. It has columns, relations and keys. For this will use the `ipl-orm` library.

So, with that out of the way, let's define the models for our two tables!

### Asset

Create a new class `Asset.php` in `library/Training/Model`:

```bash
mkdir -p library/Training/Model

vim library/Training/Model/Asset.php
```

```php
<?php

namespace Icinga\Module\Training\Model;

use ipl\Orm\Model;
use ipl\Orm\Relations;

class Asset extends Model
{
    public function getTableName()
    {
        return 'asset';
    }

    public function getKeyName()
    {
        return 'id';
    }

    public function getColumns()
    {
        return [
            'user_id',
            'serial_no',
            'manufacturer',
            'type'
        ];
    }

    public function createRelations(Relations $relations)
    {
        $relations->belongsTo('user', User::class);
    }
}
```

### User

Create a new class `User.php` in `library/Training/Model`:

```php
<?php

namespace Icinga\Module\Training\Model;

use ipl\Orm\Model;
use ipl\Orm\Relations;

class User extends Model
{
    public function getTableName()
    {
        return 'user';
    }

    public function getKeyName()
    {
        return 'id';
    }

    public function getColumns()
    {
        return ['name'];
    }

    public function createRelations(Relations $relations)
    {
        $relations->hasMany('asset', Asset::class);
    }
}
```

## Creating a Custom Widget

Now the basic setup of the database connection and ORM is done. Both are ready to use, though we still have no
view for the assets. This is what you previously set up as a view script (`*.phtml`).

However, by having `ipl-html` at our disposal we can easily replicate that in an object oriented way.
This means, creating PHP objects that can be rendered into HTML.

Hint: in official Icinga Web modules these are conventionally called a "Widget".

### Basic Structure

Usually a widget is based on the `ipl\Html\BaseHtmlElement` class. Extend it, define a tag and you have your very
first HTML element!

Though, we will use `ipl\Html\Table` instead, it is already extends `BaseHtmlElement` and provides some useful features which lets us define our table even faster.

So let us do that, shall we?

### Define the Table

Create a new class called `AssetTable` in the `Icinga\Module\Training\Web` namespace at `library/Training/Web`:

```bash
mkdir -p library/Training/Web

vim library/Training/Web/AssetTable.php
```

```php
<?php

namespace Icinga\Module\Training\Web;

use ipl\Html\Table;

class AssetTable extends Table
{
}
```

We also want to use the standard styling Icinga Web provides, so initialize the `$defaultAttributes` property:

```php
<?php // ...
    protected $defaultAttributes = ['class' => 'common-table'];
    // ...
```

It also needs the results from the database. These should be already required when creating the object:

```php
<?php // ...
    protected $assets;

    public function __construct($assets)
    {
        $this->assets = $assets;
    }
}
```

We might want to provide localization for our module. Use the trait `ipl\I18n\Translation` for this and initialize
its `$translationDomain` property:

```php
<?php // ...
use ipl\I18n\Translation;

class AssetTable extends Table
{
    use Translation;

    // ...

    public function __construct($assets)
    {
        $this->assets = $assets;
        $this->translationDomain = 'training';
    }
}
```

Now the final part.

These HTML objects can construct themselves in a method called `assemble`.

We use this to define a default layout for our table.
It should have a heading where the columns are labelled and a body of course.

```php
<?php  // ...
    protected function assemble()
    {
        $this->getHeader()->addHtml(self::row([
            $this->translate('Serial No.'),
            $this->translate('Manufacturer'),
            $this->translate('Type'),
            $this->translate('Assigned To')
        ], null, 'th'));

        $tbody = $this->getBody();
        foreach ($this->assets as $asset) {
            /** @var Asset $asset */
            $tbody->addHtml(self::row([
                $asset->serial_no,
                $asset->manufacturer,
                $asset->type,
                $asset->user->name ?? '-'
            ]));
        }
    }
}
```

Here you can also see how to access columns of the results that were fetched from the database. Columns of a model
are accessible by property or index (`$asset['serial_no']`).

If a model has relations, they are also accessible the
same way. Above this applies to the `$asset->user->name` access where `user` is our `User` model.

## Putting it all Together

We have now everything ready to start using the widget and display a table of assets. For this we need a route.

Coincidentally, we already have a controller, the `AssetsController`, just an appropriate action is missing.

The controller's route is `training/assets`, which fits our case perfectly.

Wouldn't it be nice if we could have an action that doesn't require a name? Yes we can!

`index` is the magic action name to achieve this:

```php
<?php //...

    public function indexAction()
    {
        $this->addTitleTab('Assets');
    }
}
```

The call to `addTitleTab()` sets up a tab and the page title.
If you want a different page title, use `setTitle()` afterwards.

Let us now use what we have prepared so far and show the table of assets:

```php
<?php // ...
use Icinga\Module\Training\Model\Asset;
use Icinga\Module\Training\Web\AssetTable;
//...

    public function indexAction()
    {
        $this->addTitleTab('Assets');

        $query = Asset::on($this->getDb())
            ->with('user');

        $paginationControl = $this->createPaginationControl($query);
        $limitControl = $this->createLimitControl();
        $sortControl = $this->createSortControl($query, [
            'asset.serial_no' => 'Serial No.',
            'asset.manufacturer' => 'Manufacturer',
            'asset.type' => 'Type'
        ]);

        $this->addControl($paginationControl);
        $this->addControl($sortControl);
        $this->addControl($limitControl);

        $this->addContent(new AssetTable($query));
    }
}
```

This initializes the query first. While it does that, it also specifies that the `user` relation should be explicitly
joined.

We don't have to define the columns we want, by default all columns are selected.

* Any limit and offset is applied by `createPaginationControl()` which also returns an appropriately set up `ipl\Web\Control\PaginationControl`.
* `createSortControl()` does the same regarding sort rules.
* `createLimitControl()` just returns a control to adjust the limit.

All three controls still have to be registered, this is done by passing them on to `addControl()`. If they are not,
they will not be rendered.

With the query at hand the only missing piece is our `AssetTable`, which is eventually created and registered as content.

You can now look at the result by visiting the route: http://localhost/training/assets

## Searching

At the moment the table can be sorted and the user has the ability to navigate through multiple pages. But looking
for a specific asset is tedious if done by eyeballing the entries.

We already used the trait `SearchControls` in the controller, which provides us with the tools to make this easier:

```php
<?php // application/controllers/AssetsController.php

use ipl\Html\Html;
use ipl\Web\Filter\QueryString;

//...

        // ... control initialization ...
        $searchBar = $this->createSearchBar($query, [
            $limitControl->getLimitParam(),
            $sortControl->getSortParam()
        ]);

        if ($searchBar->hasBeenSent() && ! $searchBar->isValid()) {
            if ($searchBar->hasBeenSubmitted()) {
                $filter = QueryString::parse((string) $this->params);
            } else {
                $this->addControl($searchBar);
                $this->sendMultipartUpdate();
                return;
            }
        } else {
            $filter = $searchBar->getFilter();
        }

        $query->filter($filter);

        // ... control registration ...
        $this->addControl($searchBar);

        $this->addContent(new AssetTable($query));

        if (! $searchBar->hasBeenSubmitted() && $searchBar->hasBeenSent()) {
            $this->sendMultipartUpdate();
        }
    }
}
```

This sets up the `SearchBar`. Seems quite complex at first? Yeah, possibly. But most of what you see here is only
*orchestration*.

The `SearchBar` requires a connection with many parts, which makes it impossible to abstract its
usage even more. You will see this pattern in nearly every action that makes use of the `SearchBar`. So if you
use it as well, you follow best practice so to say.

The first thing that happens here is that the search bar is initialized. It gets passed the query and a list of
parameter names, which are the parameters the search bar should ignore and preserve. Most of the time these are
parameters of other controls.

Then you see a rather large control structure. Its main use is to communicate to the user's browser that something
is wrong. If everything is okay on the other hand, (else) the filter is applied on the query.

At the end is another control structure that is used to communicate to the user's browser that only the main content
(and some selected controls) should be updated. This is the case once the search bar is automatically submitted.

If you now take a look again at the route, you will notice that the search bar appears.

### The Search Editor

You may miss the icon on the right of the search bar, which lets you open the large editor. To make this appear, we
just have to add the following to our controller:

```php
<?php // application/controllers/AssetsController.php

use ipl\Web\Control\LimitControl;
use ipl\Web\Control\SortControl;

//...

    public function searchEditorAction()
    {
        $editor = $this->createSearchEditor(Asset::on($this->getDb()), [
            LimitControl::DEFAULT_LIMIT_PARAM,
            SortControl::DEFAULT_SORT_PARAM
        ]);

        $this->getDocument()->addHtml($editor);
        $this->setTitle(t('Adjust Filter'));
    }
}
```

### Completion

We still miss a major part of the search bar and search editor: Auto-completion. This requires some more extensive
additions, which we will take a look at in detail now.

First, add a new action to the controller:

```php
<?php // ...

use Icinga\Module\Training\Web\Control\SearchBar\AssetSuggestions;

//...

    public function completeAction()
    {
        $suggestions = new AssetSuggestions($this->getDb());
        $suggestions->forRequest($this->getServerRequest());
        $this->getDocument()->addHtml($suggestions);
    }
```

This makes use of a new class which performs all the handling required.
Though, it does not exist yet so let us create it.

Create a new class `AssetSuggestions` in the namespace `Icinga\Module\Training\Web\Control\SearchBar`:

```bash
mkdir -p library/Training/Web/Control/SearchBar

vim library/Training/Web/Control/SearchBar/AssetSuggestions.php
```

```php
<?php

namespace Icinga\Module\Training\Web\Control\SearchBar;

use Icinga\Module\Training\Model\Asset;

use ipl\Sql\Connection;
use ipl\Stdlib\Filter;
use ipl\Web\Control\SearchBar\Suggestions;

class AssetSuggestions extends Suggestions
{
    /** @var Connection */
    protected $db;

    public function __construct(Connection $db)
    {
        $this->db = $db;
    }

    protected function createQuickSearchFilter($searchTerm)
    {
        $query = Asset::on($this->db);

        $filter = Filter::any();
        foreach ($query->getModel()->getSearchColumns() as $searchColumn) {
            $filter->add(Filter::like(
                $query->getResolver()->qualifyColumn($searchColumn, $query->getModel()->getTableName()),
                $searchTerm
            ));
        }

        return $filter;
    }

    protected function fetchValueSuggestions($column, $searchTerm, Filter\Chain $searchFilter)
    {
        $query = Asset::on($this->db);

        $query->columns($column);
        $query->filter(Filter::like($column, $searchTerm));

        foreach ($query as $row) {
            yield $row->$column;
        }
    }

    protected function fetchColumnSuggestions($searchTerm)
    {
        $query = Asset::on($this->db);

        foreach ($query->getResolver()->getColumnDefinitions($query->getModel()) as $name => $definition) {
            yield $name => $definition->getLabel();
        }
    }
}
```

It extends an abstract class provided by `ipl-web`. The only thing required is that it has to implement some methods
to deliver the data required to fulfill any completion requests. These are quick searches, value and column
suggestions.

The last remaining adjustment is that we also need to extend our `Asset` model slightly. We need to add some meta
data to it as the search bar and editor will greatly benefit from it:

```php
<?php // ...
    public function getSearchColumns()
    {
        return ['serial_no', 'type'];
    }

    public function getColumnDefinitions()
    {
        return [
            'serial_no' => 'Serial No.',
            'manufacturer' => 'Manufacturer',
            'type' => 'Type'
        ];
    }
```

`getSearchColumns()` does what the name implies. It is used to show a quick search suggestion in the search bar once
the user starts typing and a new condition is about to start.

`getColumnDefinitions()` provides a mapping from column names to labels.
These labels are used in the search bar and editor instead of the column paths.
They are also the source of the column suggestions and are used to validate the user's input.

### Trainings Task 1:

1. Take a look at the example data in the database, you will notice that there is a missing entry in our table.
2. Figure out why and how to fix it.

Hints:

* You can get the SQL statement of a query by using the method `dump()`
* Remember what we used to tell the ORM how our database looks like

### Trainings Task 2:

In the basic tutorial you already learned how to set up detail views for single entries. 

1. Create a detailed view for the database entries using the IPL

Hints:

* When choosing a route, think of what we did here and whether you could do the same

### Trainings Task 3:

You can request a list of column suggestions by pushing spacebar in the searchbar. However, this does not allow
to search for a user's name. Though, if you type `user.name=*uncle*` it is accepted and applied on the query.

Interesting, isn't it?

1. Figure out how you may get a relation's columns into the column suggestions. You will also
need to solve a stacktrace that appears if you request value suggestions for `user.name`.
2. Once you solved this and you typed a user name filter by assistance of the search bar, reload the page.

Mega bonus points if the label of the column is not lost! If it is, figure out why and prevent it.

# Conclusion

That's it. You now know how to set up a fully functional data view. You got an idea how some parts of the IPL
are used and what it has to offer.

There is more, of course. If you want to get an idea what is possible, it is recommended to take a look at
Icinga DB Web. It makes heavy usage of the IPL, especially of some advanced parts.

Then develop your own module with the help of the IPL. This will also greatly enhance your proficiency with it.
