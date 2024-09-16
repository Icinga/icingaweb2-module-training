# Using the Icinga DB Web Module

Adding the requirements to the `module.info`.

```
Module: mymodule
Version: 1.0.0
Requires:
  Libraries: icinga-php-library (>=0.14.0), icinga-php-thirdparty (>=0.12.0)
  Modules: icingadb (>=1.1.0)
```

Now we can use content that the module provides in our module.

## Models

```
use Icinga\Module\Icingadb\Common\Database as IcingaDatabase;
```

```php
use Icinga\Module\Icingadb\Model\Host;
use Icinga\Module\Icingadb\Model\Service;

use Icinga\Module\Icingadb\Model\Hostgroup;
use Icinga\Module\Icingadb\Model\Servicegroup;
```

```
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

## VolatileStateResults

```php
use Icinga\Module\Icingadb\Redis\VolatileStateResults;

$hosts = Host::on($db)->with(['state', 'icon_image']);
$hosts->setResultSetClass(VolatileStateResults::class);
```
