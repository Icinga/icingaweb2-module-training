# Hooks

Hooks can be used to have pre-defined spots for methods that are then interchangeable.
Meaning, you can separate implementation details from places where functionality is required.

For example, the IcingaDB Web Module provides hooks named `ServiceDetailExtensionHook` and `HostDetailExtensionHook` which we can implement in our own module to extend the details of hosts and services.

A hook is implemented as an abstract class, that we as a "hook provider" then can implement:

```php
namespace Icinga\Module\Icingadb\Hook;

abstract class HostDetailExtensionHook extends ObjectDetailExtensionHook
{
    abstract public function getHtmlForObject(Host $host): ValidHtml;
}
```

In our module we can provide a concrete class that implements - or "provides" - this hook.

These implemented hooks are placed in the `library/<modulename>/ProvidedHook/` directory. For example: `library/Training/ProvidedHook/`:

```bash
mkdir -p library/Training/ProvidedHook/Icingadb/`

vim library/Training/ProvidedHook/Icingadb/HostDetailExtension.php
```

It's generally a good idea to create a folder for each module's hooks you provide (e.g. Icingadb, Director, etc.).

Within the provided hook we can implement the `getHtmlForObject()` method the `HostDetailExtensionHook` requires:

```php
// library/Training/ProvidedHook/Icingadb/HostDetailExtension.php

<?php

namespace Icinga\Module\Training\ProvidedHook\Monitoring;

use Icinga\Module\Icingadb\Hook\HostDetailExtensionHook;
use Icinga\Module\Icingadb\Model\Host;

use ipl\Html\Html;
use ipl\Html\ValidHtml;

class HostDetailExtension extends HostDetailExtensionHook
{
    public function getHtmlForObject(Host $host): ValidHtml
    {
        return Html::tag('h2', 'A Hook Example');
    }
}
```

After implementing the hook, we need to register the hook for it to be active.
Our module already has the `provideHook()` method to achieve this.

We call this method in our module's `run.php` file in the root directory:

```php
// run.php

<?php

$this->provideHook('icingadb/HostDetailExtension');
```

Here you can see that we register the `icingadb/HostDetailExtension` hook via our previously created class.

**Hint:** beware that code in `run.php` is loaded by the Icinga Web application on every request, when the module is enabled.
Use it only when necessary (e.g. registering hooks).

# Creating your own Hook

In order to create our own Hook we first create an abstract class that represents the hook.
These abstract classes are placed in the `library/<modulename>/Hook/` directory. For example: `library/Training/Hook/`.

We will improve the `FileController.php` from the previous section by adding a hook:

```bash
mkdir -p library/Training/Hook

vim library/Training/Hook/FileListViewHook.php
```

The hook will take the file path as a parameter and return HTML for the view:

```php
<?php

namespace Icinga\Module\Training\Hook;

use ipl\Html\ValidHtml;

abstract class FileListViewHook
{
    abstract public function getHtmlForFile(string $filepath): ValidHtml;
}
```

Hint: A hook can return anything, not just `ValidHtml`.

Now anyone can implement this Hook in another module, register it and we can call its methods.

The `Icinga\Web\Hook` class provides various methods to retrieve registered hook:

* `Hook::has($name)`, whether or not someone registered the given hook name
* `Hook::all($name)`, get the all hooks by name
* `Hook::first($name)`, get the first hook by name

We update the FileController's `showAction` to get all `Training\FileListView` hooks anyone might have provided and then call the `getHtmlForFile` method:

```php
// application/controllers/FileController.php

<?php

namespace Icinga\Module\Training\Controllers;

use Icinga\Web\Hook;

use Icinga\Web\Controller;
use Icinga\Module\Training\Directory;

class FileController extends Controller
{
    public function listAction()
    {
        $this->view->files = Directory::listFiles($this->Module()->getBaseDir());
    }
    public function showAction()
    {
        $f = join('/', [$this->Module()->getBaseDir(), $this->params->getRequired('file')]);
        $this->view->filesize = filesize($f);

        $this->view->extensionsHtml = [];

        foreach (Hook::all('Training\FileListView') as $hook) {
            try {
                $html = $hook->getHtmlForFile($f);
            } catch (Exception $e) {
                $html = $this->view->escape($e->getMessage());
            }

            if ($html) {
                $this->addContent($html);
            }
        }

    }
}
```

Now users of our module can provide this hook to extend the controller's data.

## Implementing a Hook

We can test our new hook by creating a class that implements it.

```bash
mkdir -p library/Training/ProvidedHook/Training/

vim library/Training/ProvidedHook/Training/Example.php
```

For example, since we pass a path to a file we could retrieve its modification time:

```php
// library/Training/ProvidedHook/Training/Example.php

<?php

namespace Icinga\Module\Training\ProvidedHook\Training;

use ipl\Html\ValidHtml;

use Icinga\Module\Training\Hook\FileListViewHook;

class Example extends FileListViewHook
{
    public function getHtmlForFile(string $filepath): ValidHtml
    {
        if (file_exists($filepath)) {
            $mtime = filemtime($filepath);

            $main = HtmlElement::create('div', ['class' => 'file-details']);
            $header = Html::tag('h2', 'File Modification Time'));
            $content = Html::tag('h2', HtmlString::create($mtime));

            $main->add($header);
            $main->add($content);
            return $main;
        }
    }
}
```

Finally, we register our hook implementation in the `run.php`:

```php
// run.php

<?php

use Icinga\Module\Training\ProvidedHook\Training\Example;

// This is an example when the class providing the hook is named differently
$this->provideHook('training/FileListView', 'Icinga\Module\Training\ProvidedHook\Training\Example'

// If we would have named the class FileListView instead of Example
// $this->provideHook('training/FileListView');
);
```

## Useful Hooks

The following will list some of the available Hooks you can implement.

### DetailExtensionHooks

The `HostDetailExtensionHook` and the `ServiceDetailExtensionHook` can be used to extend the
HTML representation of a given host or service.

```php
use Icinga\Module\Icingadb\Hook\HostDetailExtensionHook;
use Icinga\Module\Icingadb\Hook\ServiceDetailExtensionHook;
```

### HealthHook

The `HealthHook` can be used to display a overall health status of the module in Icinga Web's System Health page.

```php
namespace Icinga\Module\Training\ProvidedHook;

use Icinga\Application\Hook\HealthHook;

class Health extends HealthHook
{
  public function getName(): string
  {
      return 'Training Module';
  }

  public function checkHealth(): void
  {
        $this->setState(self::STATE_OK);
        $this->setMessage('Training Module is healthy');
  }
}
```

This can be used for various things (e.g. verifying the connection to an external requirement, internal status of the module, etc.).

### DbMigrationHook

The `DbMigrationHook` can be used to automatically perform database migrations.

```php
use Icinga\Application\Hook\DbMigrationHook;
```

The next section will cover this in detail.
