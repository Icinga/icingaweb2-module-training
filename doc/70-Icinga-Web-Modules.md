# Working with other Icinga Web Modules

There are many Icinga Web modules out there, sometimes want you want is use already existing functionality inside your own module.

This section will show you how to work with some of the modules that Icinga offers.

## IcingaDB

To use the IcingaDB module inside your own module, first, declare it as a dependency:

```
Module: mymodule
Version: 1.0.0
Requires:
  Libraries: icinga-php-library (>=0.14.0), icinga-php-thirdparty (>=0.12.0)
  Modules: icingadb (>=1.1.0)
```

Now we can use content that the IcingaDB module provides in our module.

Hint: If you want to support both IcingaDB and the Monitoring module you can use: `Modules: icingadb (>=1.1.0), monitoring (>= 2.12.0)`

### Models

Like many modules, the IcingaDB module comes with its own database connection and models. We can import and use these.

To import the database configured for the IcingaDB module:

```php
use Icinga\Module\Icingadb\Common\Database as IcingaDatabase;
```

To use the models:

```php
use Icinga\Module\Icingadb\Model\Host;
use Icinga\Module\Icingadb\Model\Service;

use Icinga\Module\Icingadb\Model\Hostgroup;
use Icinga\Module\Icingadb\Model\Servicegroup;
```

Now we can for example retrieve all services from the database:

```php
$services = Service::on($this->getDb())->with([
    'state',
    'host',
    'host.state'
]);

foreach ($services as $service) {
    $s = Html::tag('p', $service->name);
    $h = Html::tag('strong', $service->host->name);
    $s->addHtml($h);

    $this->addContent($s);
}
```

### IcingadbSupportHook

This hook can be used to signal that a module supports IcingaDB,
which can be useful when you want to maintain backward compatibility with the Monitoring module.

The hook does not require you to implement any methods:

```php
use Icinga\Module\Icingadb\Hook\IcingadbSupportHook;

class IcingadbSupport extends IcingadbSupportHook
{
}
```

You can also use it inside your module to determine whether or not IcingaDB is used:

```php
if (Module::exists('icingadb') && IcingadbSupport::useIcingaDbAsBackend()) {
  Logger::debug('Used IcingaDB as database backend');
} else {
  Logger::debug('Used IDO as database backend');
}
```
