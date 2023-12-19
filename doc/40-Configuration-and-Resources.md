# Module Configuration

Icinga Web modules usually require some configuration. This could be database connection, URLs, Tokens, or whatever the module needs to provide its functionality.

We can add configuration tabs for our module that will be shown in the Icinga Web module overview.

For this we use the `provideConfigTab()` method in the `configuration.php`.

```php
$this->provideConfigTab(
    'database',
    [
        'title' => $this->translate('Database'),
        'label' => $this->translate('Database'),
        'url'   => 'config/database'
    ]
);
```

We now need to create a Controller that will provide the `config/database` endpoint and a Form that will be shown there.

To begin we create a simple Form at `application/forms/DatabaseConfigForm.php`. We will use this Form to set the name of our currently hard-coded `assets.sqlite` database file.

```php
<?php

namespace Icinga\Module\Training\Forms;

use ipl\Web\Compat\CompatForm;

class DatabaseConfigForm extends CompatForm
{
    protected function assemble()
    {
        $this->addElement('text', 'dbfile', ['label' => 'Database File']);

        $this->addElement(
            'submit',
            'submit',
            [
                'label' => $this->translate('Save Changes')
            ]
        );
    }
}
```

This will store the given text value in a `dbfile` key (`dbfile = foobar`).

The next step is a `ConfigController` with a `databaseAction()` that will provide the endpoint `config/database`.

Within the Controller we use the `Icinga\Application\Config` class to read and write the config data.
This class has a static function that can be used to load a module's configuration `Config::module()`.

```php
$moduleConfig = Config::module('training');
$moduleConfig->getSection('database')
```

We can get/set an INI section and then store it to the module's configuration file.

```php
$moduleConfig->setSection('database', $form->getValues());
$moduleConfig->saveIni();
```

The ConfigController could look like this:

```php
<?php

namespace Icinga\Module\Training\Controllers;

use Icinga\Module\Training\Forms\DatabaseConfigForm;

use Icinga\Application\Config;
use Icinga\Web\Widget\Tab;
use Icinga\Web\Widget\Tabs;
use Icinga\Web\Notification;
use ipl\Web\Compat\CompatController;

class ConfigController extends CompatController
{
    public function init()
    {
        $this->assertPermission('config/modules');
        parent::init();
    }

    public function databaseAction()
    {
        $moduleConfig = Config::module('training');
        $form = new DatabaseConfigForm();
        $form->populate($moduleConfig->getSection('database'))
            ->on(DatabaseConfigForm::ON_SUCCESS, function ($form) use ($moduleConfig) {
                $moduleConfig->setSection('database', $form->getValues());
                $moduleConfig->saveIni();

                Notification::success('New configuration has successfully been stored');
            })->handleRequest($this->getServerRequest());

        $this->mergeTabs($this->Module()->getConfigTabs()->activate('database'));

        $this->addContent($form);
    }

    /**
     * So that we see the Module Tab and the config tab together
     */
    protected function mergeTabs(Tabs $tabs): void
    {
        foreach ($tabs->getTabs() as $tab) {
            $this->tabs->add($tab->getName(), $tab);
        }
    }
}
```

This will load the current values from the `database` section and populate the DataBaseConfigForm with it. On saving, it will store the given values in the `database` section.

Everything will get written to `/etc/icingaweb2/modules/training/config.ini`

We can now open our DatabaseConfigForm, where we can enter `assets.sqlite` and save. Our config should now look like this:

```
[Database]
dbfile = "assets.sqlite"
```

Anywhere in our module we can now use the `Icinga\Application\Config` class to retrieve this data.

```php
use Icinga\Application\Config;

// get('section', 'entry')
Config::module('training')->get('database', 'foobar');
Config::module('anothermodule')->get('db', 'resource');
```

## Database Refactor

We can use this new config to refactor our database connection to be in a common place:

In `library/Training/Database.php` we can create a common database setup:

```php
<?php

namespace Icinga\Module\Training;

use Icinga\Application\Config;
use Icinga\Application\Icinga;
use ipl\Sql\Connection;

final class Database
{
    private static $db;

    public static function get()
    {
        $filename = Config::module('training')->get('database', 'dbfile');
        $dir = Icinga::app()->getModuleManager()->getModule('training')->getConfigDir();

        if (self::$db === null) {
            self::$db = new Connection([
                'db' => 'sqlite',
                'dbname' => $dir . '/'. $filename
            ]);
        }

        return self::$db;
    }
}
```

Now we can simply use this to get our database connection:

```php
use Icinga\Module\Training\Database;

$db = Database::get()
```

And we can replace the `getDb()` method in our controllers with this:

```php
public function init()
{
    $this->db = Database::get();
}
```

# Resources

Instead of having data sources - such as databases - scattered across many modules, Icinga Web provides a central `resources.ini` file that contains information about data sources. These can be referenced in other configuration files.

This allows you to manage all data sources in a central place, avoiding the need to edit several different files when the information about a data source changes.

We can use this to improve our module by using a `File` resource for our `assets.sqlite` file.

For this we first add a `File` resource in the Icinga Web configuration `config/resource`:

* Resource Type: `File`
* Resource Name: `assets`
* Filepath: `/etc/icingaweb2/modules/training/assets.sqlite`
* Pattern: `//`

To work with these resources we use the class `Icinga\Data\ResourceFactory`.

This class can provide us all available resources via the `getResourceConfigs('file')` method, or the content of a specific resource via the `getResourceConfig('assets')` method.

We can thus replace the `text` element in the `DatabaseConfigForm` with a `select` element that will show all available `File` resources:

```php
$fileResources = ResourceFactory::getResourceConfigs('file')->keys();

$this->addElement(
    'select',
    'resource',
    [
        'label'   => $this->translate('Database'),
        'options' => array_merge(
            ['' => sprintf(' - %s - ', $this->translate('Please choose'))],
            array_combine($fileResources, $fileResources)
        ),
        'disable'  => [''],
        'required' => true,
        'value'    => ''
    ]
);
```

With the new resource and configuration in place, we can refactor the database setup in `library/Training/Database.php`:

```php
<?php

namespace Icinga\Module\Training;

use Icinga\Application\Config;
use Icinga\Data\ResourceFactory;
use Icinga\Application\Config;
use ipl\Sql\Connection;

final class Database
{
    private static $db;

    public static function get()
    {
        $f = Config::module('training')->get('database', 'resource');
        $r = ResourceFactory::getResourceConfig($f);

        if (self::$db === null) {
            self::$db = new Connection([
                'db' => 'sqlite',
                'dbname' => $r->filename
            ]);
        }
}
```

Of course we would use a `Database` resource in a real Icinga Web module.

Further information on resources can be found here:

* https://icinga.com/docs/icinga-web/latest/doc/04-Resource
