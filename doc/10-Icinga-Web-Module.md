# The Web Module

Icinga Web modules follow the **model–view–controller (MVC)** pattern.

* Model manages data and business logic
* View handles the user interface
* Controller manages user input and updates the Model and View

This is reflected in the module structure:

    .
    └── training                Basic directory of the module
        ├── configuration.php   Deploy menu, dashlets, permissions
        ├── application
        │   ├── controllers     Web Controller
        │   └── views
        │       ├── helpers     View Helper
        │       └── scripts     View Scripts
        └── library
            └── Training        Library Code, Module Namespace
                └── Model

## Controllers

The controller acts as an intermediary, managing user input and updating the model and view accordingly.

To create a 'Hello World' controller, we need to create its directory:

```bash
mkdir -p application/controllers
```

Now add the controller in a file called `HelloController.php`:

```php
<?php

namespace Icinga\Module\Training\Controllers;

use Icinga\Web\Controller;

class HelloController extends Controller
{
    public function worldAction()
    {
    }
}
```

All controllers MUST inherit the `Icinga\Web\Controller` class.

The class name HelloController MUST correspond to the file name.

Every `action` in a `controller` automatically becomes a `route` in our web frontend. It looks something like this:

```
http(s)://<host>/icingaweb2/<module>/<controller>/<action>
```

If we call the URL `training/hello/world` now, we get an error message:

```
Server error: script 'hello/world.phtml' not found in path
(/usr/local/icingaweb2-modules/training/application/views/scripts/)
```

Conveniently, it immediately tells us what we need to do next.

## Creating a View

Since we create a view script in a dedicated file per `action` there is a directory for each controller:

```bash
mkdir -p application/views/scripts/hello
```

The view script's name corresponds to the controller's action, so `world.phtml`:

```php
<h1>Hello World!</h1>
```

That's it, our new URL is now available.

We can now use the full scope of our module and style it accordingly. Two important predefined CSS classes are `controls` and `content`, for header elements and the page content.

```php
<div class="controls">
<h1>Hello World!</h1>
</div>

<div class="content">
Some content...
</div>
```

This automatically gives even spacing to the page margins, and also makes it so that when scrolling down,
the `controls` stay stationary, while the `content` scrolls.

## Menu Entry and Dashboard

To create an entry in the Icinga Web main menu we need to create a `configuration.php` file in the module's root directory.

```bash
vim configuration.php
```

What we see here is a global configuration that is located in the base directory of your own module


```php
<?php

$this->menuSection('Training')
     ->add('Hello World')
     ->setUrl('training/hello/world');
```

Menu entries in Icinga Web can also be personalized or predefined by the administrator.

### Icons for menu entries

To make our menu item look even better, we can add icons in front of it:

```php
<?php

$trainingMenu = $this->menuSection('Training')
     ->setIcon('thumbs-up')
     ->setPriority(10);

$trainingMenu->add('Hello World')
     ->setUrl('training/hello/world');
```

To have a look at the available icons, we can activate the `doc` module under `Configuration`/`Modules`.

If the module is active, you can find the icon list under `Documentation`/`Developer - Style`.

These icons have been embedded in a font, which allows them to be styled the same as text.

Alternatively, you can still use classic icons as images if you wish:

```php
<?php
$trainingMenu->setIcon('img/icons/success.png');
```

### Side note: Alternative menu syntax

Alternatively we could use this syntax:

```php
<?php
$this->menuSection('Training'), [
  'icon' => 'beaker',
  'url'  => 'training'
]);
```

## Dashboards

Dasboards can also be created in the `configuration.php` file.

```php
<?php
$this->dashboard('Training')->add('Hello', 'training/hello/world');
```

# Adding data

With our web routes ready, we want to do something more meaningful with them.

The workflow in an MVC application usually looks like this:

The **controller** gets its data with the aid of its **model**, and then passes it on to the **views** for displaying.

## Passing data to a view

The controller provides access to our view with the `$this->view` property.

The action in the `HelloController.php` can set the data like this:

```php
<?php
    public function worldAction()
    {
        $this->view->application = 'Icinga Web';
        $this->view->moreData = [
            'Work'   => 'done',
            'Result' => 'fantastic'
        ];
    }
```

We can now expand our `world.phtml` view and display the new data:

```php
<div class="controls">
  <h3>Some data...</h3>
</div>

<div class="content">
  <p>This example is provided by <?= $this->qlink('Icinga', 'http://www.icinga.com') ?>
    and based on <?= $this->application ?>.</p>

  <table>
  <?php foreach ($this->moreData as $key => $val): ?>
      <tr>
          <th><?= $key ?></th>
          <td><?= $val ?></td>
      </tr>
  <?php endforeach ?>
  </table>
</div>
```

### Training Task: 1

1. Create a controller that creates a table of this modules's files at `training/list/files`

Note: `$this->Module()->getBaseDir()` returns the module's directory

More about opening directories in the [PHP documentation](https://www.php.net/manual/en/function.opendir.php)

# Adding Images

If you would like to use your own images in your module, you can simply provide them under `public/img`:

```bash
mkdir -p public/img/

# Example Image
cp doc/images/icinga.png public/img/
```

All images are immediately accessible in the web interface, the URL pattern is as follows:

```
http(s)://<icingaweb2>/img/<module>/<image-name>
```

In our case that would be: `http://localhost/img/training/icinga.png` or `img/training/icinga.png`. We can use the latter path in our view.

HTML `<img>` elements can be created using the `img` helper function:

```php
<div class="content">

<?= $this->img('img/training/icinga.png', [], ['title' => 'Icinga']) ?>

</div>
```

The first parameter is the path to the image, the second parameter is an array containing URL parameters, the third parameter is an array containing further HTML attributes.

```php
<div class="content">

<?= $this->img('img/training/icinga_icon.png', [], ['title' => Icinga, 'width' => '100%;']) ?>

</div>
```

# Adding CSS

We can add custom CSS to a module by placing a `module.less` file in the directory `public/css`.

```bash
mkdir -p public/css

vim public/css/module.less
```

Style sheets can be written in pure CSS or [Less](https://lesscss.org/), a CSS extension, which adds a variety of functions.

```css
table {
    width: 100%;
}

th {
    width: 20%;
    text-align: right;
    line-height: 2em;
    padding-right: 2em;
}
```

The nice thing about Icinga Web is, that there is no need to worry about whether ones CSS will influence other modules - or
Icinga Web itself.

When inspecting the requests in the browser's developer tools, we see that Icinga Web only loads `css/icinga.min.css`.

We can also use the path `css/icinga.css` to conveniently view the "unminified" CSS:

```css
.icinga-module.module-training table {
  width: 100%;
}
.icinga-module.module-training th {
  width: 20%;
  text-align: right;
  line-height: 2em;
  padding-right: 2em;
}
```

Automatic prefixes ensure that our CSS only applies to the `containers`, in which our module's content is rendered.

## Useful CSS classes

Icinga Web provides a set of CSS classes that make our job easier:

* `common-table` can be used for tables
* `table-row-selectable` makes entry rows selectable and clickable
* `name-value-table` for name/value pairs (`td` with name on the left, `td` with the value on the right)

# Creating a Data Model

Currently our controller holds all data, this is not a good practice. It also might cause some problems, for example if we want to use the data on the CLI.

## Our own library

We are going to create a new directory for the library we want to use in our module, following the scheme `library/<Modulename>`.

```bash
mkdir -p library/Training
```

For our module we will use the namespace `Icinga\Module\<Modulename>`. The module name's and directory's first letter MUST be uppercase.

Icinga Web will automatically search for any namespace created within `Training` in the newly created directory.

There are some exceptions to that rule:

 * `Icinga\Module\Training\Clicommands`
 * `Icinga\Module\Training\Controllers`
 * `Icinga\Module\Training\Forms`

Any sub-directory of `library/Training` represents its own namespace. For example:

* `library/Training/FileSystem` uses `Icinga\Module\Training\FileSystem`
* `library/Training/FileSystem/FileInfo` uses `Icinga\Module\Training\FileSystem\FileInfo`

A class, that implements the solution for the last exercise, might be in `library/Training/Directory.php`:

```php
<?php

namespace Icinga\Module\Training;

use DirectoryIterator;

class Directory
{
    public static function listFiles(string $path): array
    {
        $result = [];
        foreach (new DirectoryIterator($path) as $file) {
            if ($file->isDot()) {
                continue;
            }

            $result[] = $file->getFilename();
        }

        return $result;
    }
}
```

The class name MUST be the same as the filename.

A `FileController.php` controller can now retrieve the data via this class:

```php
<?php
use Icinga\Module\Training\Directory;

class FileController extends Controller
{
    public function listAction()
    {
        $this->view->files = Directory::listFiles($this->Module()->getBaseDir());
    }
}
```

The corresponding view could look like this:

```php
<div class="controls">
 <h1>File List</h1>
</div>

<div class="content">

 <table class="common-table table-row-selectable">
  <thead>
   <tr>
    <th>File</th>
   </tr>
  </thead>

  <tbody>
  <?php foreach ($this->files as $k => $file): ?>
      <tr>
          <td><?= $this->qlink(
                  $file,
                  'training/file/show',
                  ['file' => $file],
                  ['icon' => 'doc-text']
              ) ?>
          </td>
      </tr>
  <?php endforeach ?>
  </tbody>

 </table>
</div>
```

Other useful features in the view are:

* `escape($value)` to escape the given value to be safely used in view scripts
* `img($url, $params, $properties)` to render an image
* `url($patt, $params)` to create an URL for links
* `qlink($title, $url, $params, $properties, $escape)` to create a link

# Parameter handling

So far we have not added any parameters to our routes. Similar to the command line, Icinga Web provides simple access to URL parameters.

Access is as follows:

```php
<?php
// Will return null if the parameter is missing
$file = $this->params->get('file');

// Will throw an Exception if the parameter is missing
$this->params->getRequired('file')
```

`shift()` and the like are available as well.

### Training Task: 2

1. Add an `show` action to the `FileController.php`
2. Use the URL parameter `file` in the new `show` action to display additional information about the given file

You can display owners, permissions, last change and mime-type - but it is also quite simple enough to
display name and size in a more orderly fashion.

# URL handling and multi column layout

To avoid problems with parameter escaping, we use the helper function `qlink`:

```php
<td><?= $this->qlink(
        // The text to be displayed
        $file,
        // The route to use
        'training/file/show',
        // URL parameters
        ['file' => $file],
        // Optional parameters
        ['icon' => 'doc-text']
    ) ?>
</td>
```

If we now click on a file in our list, we get the corresponding details displayed.

But there is a more comfortable way to do this, by using the multi column layout of Icinga Web.

We can add the attribute `data-base-target="_next"` to the `<div class="content">` in the `list` view:

```html
<div class="content" data-base-target="_next">
```

Other options for the `data-base-target` are:

* `_next`
* `_self`
* `col1`, `col2`, `col3`

Those who has keep a watch on how their browser behaves, may have noticed that not every click reloads the page.
Icinga Web intercepts all requests and sends them separately via XHR request. On the server side, this is detected,
and then only the respective HTML snippet is sent as a response. The response usually only matches the output created
by the corresponding view script. This type of web application is also known as *Single Page Application*. (SPA)

Yet, each link remains a link and can e.g. be opened in a new tab. There it is recognized that this is not an
XHR request and the entire layout is delivered.

Usually, links always open in the same container, but you can influence the behavior with `data-base-target`.
The attribute closest to the clicked element wins. If you want to override the `_next` for a section of the page,
simply set `data-base-target="_self"` on the element.

## Autorefresh

As a monitoring interface, it goes without saying, that Icinga Web provides a reliable and stable autorefresh
functionality.

This can be conveniently managed in the controllers:

```php
<?php
    public function listAction()
    {
        // ...

        $this->setAutorefreshInterval(10);
    }
```

### Training Task: 3

Our file list should update automatically, the detail information panel should as well.

1. Show the last modification date of a file (`$file->getMtime()`) and use the `timeSince` helper to display the time.
2. Change a file see what happens. How can that be explained?

# Configuration

Those who develop a module would most likely want to be able to configure it too.

The configuration for a module is stored at `/etc/icingaweb2/modules/<modulename>/config.ini`.

Everything found in the `config.ini` file, is accessible in the controller:

```php
<?php
/*
Example config.ini

[section]
entry = "value"
*/

public function configAction()
{
    $config = $this->Config();
    echo $config->get('section', 'entry');

    // Returns 'default' because 'noentry' does not exist:
    echo $config->get('section', 'noentry', 'default');

    // Reads from the special.ini instead of the config.ini:
    $special = $this->Config('special');
}
```

## Training Task: 4

1. Make the base path for the `list` controller configurable
2. Use the `module directory` if no path is configured

# Using Icinga Web logic in third party software

With Icinga Web we want to make the integration of third party software as easy as possible.

We also want to make it easy for others to use Icinga Web logic in their software.

The following call in any PHP file is enough to achieve this:

```php
<?php

require_once '/usr/local/icingaweb2/' // Must fit your system
    . 'library/Icinga/Application/EmbeddedWeb.php';
Icinga\Application\EmbeddedWeb::start(
    '/usr/local/icingaweb2'
);
```

Done! No authentication, no bootstrapping of the full web interface. But any library code can be used.
