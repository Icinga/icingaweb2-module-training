# Hooks

Hooks are a way for one piece of code to interact another piece of code at specific, pre-defined spots.

For example, Icinga Web provides a hook named `DetailviewExtensionHook` which is used when displaying the details of hosts and services:

```php
use Icinga\Web\Hook;

foreach (Hook::all('Monitoring\DetailviewExtension') as $hook) {
    try {
        $html = $hook->setView($this->view)->getHtmlForObjects($this->serviceList);
    } catch (Exception $e) {
        $html = $this->view->escape($e->getMessage());
    }
}
```

This snippet is from Icinga Web's `ServicesController`. Here we can see that we could use the `DetailviewExtension` hook
to render custom HTML for a given object.

The `Icinga\Web\Hook` class provides various methods to retrieve registered hook:

* `Hook::has($name)`, whether or not someone registered the given hook name
* `Hook::all($name)`, get the all hooks by name
* `Hook::first($name)`, get the first hook by name

A hook is implemented as an abstract class, that we as a "hook provider" then need to implement:

```php
namespace Icinga\Module\Monitoring\Hook;

abstract class DetailviewExtensionHook
{
    abstract public function getHtmlForObject(MonitoredObject $object);
}
```

These abstract classes are placed in the `library/<modulename>/Hook/` directory. For example: `library/Training/Hook/`.

Now we can provide a concrete class that implements - or provides - this hook.

These contract hooks are placed in the `library/<modulename>/ProvidedHook/` directory. For example: `library/Training/ProvidedHook/`:

```bash
mkdir -p library/Training/ProvidedHook/Monitoring/`

vim library/Training/ProvidedHook/Monitoring/DetailviewExtension.php
```

It's generally a good idea to create a folder for each module's hooks you provide (e.g. Monitoring, Director, etc.).

Within the provided hook we can implement the `getHtmlForObject()` method the `DetailviewExtensionHook` requires:

```php
// library/Training/ProvidedHook/Monitoring/DetailviewExtension.php

<?php

namespace Icinga\Module\Training\ProvidedHook\Monitoring;

use Icinga\Module\Monitoring\Hook\DetailviewExtensionHook;
use Icinga\Module\Monitoring\Object\MonitoredObject;

class DetailviewExtension extends DetailviewExtensionHook
{
    public function getHtmlForObject(MonitoredObject $object)
    {
        return '<h2>Hello World</h2>';
    }
}
```

After implementing the hook, we need to register the hook for it to be active.
Our module already has the `provideHook()` method to achieve this.

We call this method in our module's `run.php` file in the root directory:

```php
// run.php

<?php

use Icinga\Module\Training\ProvidedHook\Monitoring\DetailviewExtension;

$this->provideHook(
    'monitoring/DetailviewExtension',
    'Icinga\Module\Training\ProvidedHook\Monitoring\DetailviewExtension'
);
```

Here you can see that we register the `monitoring/DetailviewExtension` hook via our previously created class.

**Hint:** beware that code in `run.php` runs on every request, use it only when necessary (e.g. registering hooks).

# Creating a Hook

In order to create our own Hook we first create an abstract class that represents the hook.

We will improve the `FileController.php` from the previous section by adding a hook:


```bash
mkdir -p library/Training/Hook

vim library/Training/Hook/FileListViewHook.php
```

The hook will take the file path as a parameter and return HTML for the view:

```php
<?php

namespace Icinga\Module\Training\Hook;

abstract class FileListViewHook
{
    abstract public function getHtmlForFile(string $filepath);
}
```

Now we update the FileController's `showAction` to get all `Training\FileListView` hooks anyone might have provided and then call the `getHtmlForFile` method:

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
                $this->view->extensionsHtml[] = $html;
            }
        }

    }
}
```

We also need to update our view to display the new data:

```php
// application/views/scripts/file/show.phtml

<div class="controls">
<h1>File Details</h1>
</div>

<div class="content">
<?= $this->filesize ?>

<?php
foreach ($extensionsHtml as $ext) {
    echo $ext;
}
?>
</div>
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

use Icinga\Module\Training\Hook\FileListViewHook;

class Example extends FileListViewHook
{
    public function getHtmlForFile(string $filepath)
    {
        if (file_exists($filepath)) {
            $mtime = filemtime($filepath);
            return '<h2>File Modification Time</h2><p>'. $mtime. '</p>';
        }
    }
}
```

Finally, we register our hook implementation in the `run.php`:

```php
// run.php

<?php

use Icinga\Module\Training\ProvidedHook\Training\Example;

$this->provideHook(
    'training/FileListView',
    'Icinga\Module\Training\ProvidedHook\Training\Example'
);
```
