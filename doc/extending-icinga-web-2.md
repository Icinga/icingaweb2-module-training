# Extending Icinga Web

## Write your own Icinga Web module

Welcome! Glad to see that you are here to write your first Icinga Web module. Icinga Web makes getting started as easy
as possible. Over the next few hours we will discover how fun tinkering with Icinga Web can be, with a series of
practical examples.

## Should I really? Why?

Absolutely, why not? It's incredibly straightforward, and Icinga is 100% free, open source software with a great
community. Icinga Web is a stable, easy to understand and future-proof platform. So exactly what you want to base
your own projects on.

## Only for monitoring?

Not at all! Sure, monitoring is where Icinga Web originates and it's what it excels at. Since monitoring systems
communicate with all sorts of systems in and outside of ones data center anyway, we found it to be the most natural
thing to have the frontend behave in a similar fashion.

Icinga Web is a modular framework, which aims to make integration of third-party software as easy as possible.
At the same time, true to the Open Source concept, we also want to make it easy for third parties to use Icinga logic,
as conveniently as possible, in their own projects.

Whether it is about integrating third-party systems, the connection of a CMDB or the visualization of complex systems
to supplement popular check-plugins - there is no limit to what you can do.

## But I'm not a PHP/JavaScript/HTML5 hacker

No problem. Of course, it doesn't hurt to know the basics of web development. This way or the other - Icinga Web allows
you to write your own modules with our without in-depth PHP/HTML/CSS knowledge.

# Preparation

As a little warm up for our notebooks, we'll start off with [installing Icinga Web](https://icinga.com/docs/icinga-web/latest/doc/02-Installation/).

Before we get that ball rolling, we will begin with a little introduction!

## Overview of the training

* Overview of Icinga Web
* Creating your own module
  * Own CLI commands
  * Working with parameters
  * Colors and other tricks
* Extending the web frontend
  * Own images
  * Own stylesheets
  * Extending the menu
  * Providing dashboards
* Working with data
  * Providing data
  * Bundle code in libraries
  * Working with parameters
  * Tips for work routines
* Configuration
* Translations
* Integration in third-party software
* Concluding remarks

## Icinga Web Architecture

During the development of Icinga Web, we built on three pillars:

* Simplicity
* Speed
* Reliability

Although we have dedicated ourselves to the DevOps movement, our target audience with Icinga Web is, first and foremost,
the operator - the admin. Therefore, we try to have as few dependencies as possible on external components. We forgo
using some of the newest and hippest features, as it prevents things from breaking on updating to the newest versions.

The web interface is designed to be displayed on a dashboard for weeks and even months. We want to be able to rely on,
that what we see, corresponds to the current state of our environment. If there are problems, they are visualized - even
if they are within the application itself. When the problem is resolved, everything must continue as usual. And that
without anyone having to plug in a keyboard and intervene manually.

## Libraries used

* icinga-php-library
* icinga-php-thirdparty
* Zend Framework 1.x
* HTMLPurifier
* jQuery 3

## Anatomy of an Icinga Web module

Icinga Web follows the paradigm 'convention before configuration'. A lesson learnt from our development of its
predecessor: one of the best tools for XML processing is on every disk: `/bin/rm`. Those who stick to a few
simple conventions will save a lot of configuration work. Basically, in Icinga Web you only have to configure
paths for special cases. It is usually enough to just save a file, in the right place.

An extensive, mature module could have approximately the following structure:

    .
    └── training                Basic directory of the module
        ├── application
        │   ├── clicommands     CLI Commands
        │   ├── controllers     Web Controller
        │   ├── forms           Forms
        │   ├── locale          Translations
        │   └── views
        │       ├── helpers     View Helper
        │       └── scripts     View Scripts
        ├── configuration.php   Deploy menu, dashlets, permissions
        ├── doc                 Documentation
        ├── library
        │   └── Training        Library Code, Module Namespace
        ├── module.info         Module Metadata
        ├── public
        │   ├── css             Own CSS Code
        │   ├── img             Own Images
        │   └── js              Own JavaScript
        ├── run.php             Registration of hooks and more
        └── test
            └── php             PHP Unit Tests

We will work on our module, step by step, during this training and fill it with life.

## Source Tree preparation

To get started, we need Icinga Web. This can be checked out of the GIT Source Tree and used as it comes. If you then set
`DocumentRoot` for a properly configured web server in the `public` directory, you can start already. For testing
purposes it's even easier:

    cd /usr/local
    # If not done yet
    git clone https://github.com/Icinga/icingaweb2.git
    ./icingaweb2/bin/icingacli web serve

Finished. To use the installation wizard, a token is required, for security reasons. The wizard prompts you to enter a
token, which is to be generated in the CLI. This is to ensure that, between installation and setup, there is never a
time when an attacker could take over an environment. For packagers this point is completely optional, the same
applies to those, who roll out Icinga Web with a CM tool like Puppet: if there is a configuration on the system,
you will never see the Wizard.

    http://localhost

## Manage multiple module paths

Especially those who always work with the latest version, or want to switch between GIT branches safely, usually do not
want to have to change files in their working copy. Therefore, it is recommended to use several module paths in parallel
from the start. This can be done in the system settings or in the configuration at `/etc/icingaweb2/config.ini`:

    [global]
    module_path = "/usr/local/icingaweb2-modules:/usr/local/icingaweb2/modules"

## Installation from packages

Icinga builds up-to-date snapshots daily, for a wide range of operating systems.
The packages are available at [packages.icinga.com](https://packages.icinga.com/).

But for our training we will use the Git repository directly.

# Create your own module

## Where should I start?

Probably the most important question is usually what you want to do with this module. In our training we will first
experiment with the given possibilities and then implement a small practical example.

## What should I name my module?

Once you know what the module is going to do, the hardest task is often choosing a good name. Ideally, it will tell you
what the module actually does. But the name should not be too complicated, because we will use it in PHP namespaces,
directory names, and URLs.

Your own (company) name is often a good starting point. Our chosen module name for our first steps in training today
will be `training`.

## Create and activate a new module

    mkdir -p /usr/local/icingaweb2-modules/training
    icingacli module list installed
    icingacli module enable training

And done!

# Extending Icinga CLI

The Icinga CLI was designed to provide most of the application logic in Icinga Web, and its modules, on the
commandline. This aims to make the creation of cronjobs, plugins, useful tools and smaller services as
easy as possible.

## Own CLI Commands

Structure of the CLI commands:

    icingacli <module> <command> <action>

Creating a CLI command is very easy. The directory `application/clicommands` will create a file, whose name
corresponds to the desired command:

    cd /usr/local/icingaweb2-modules/training
    mkdir -p application/clicommands
    vim application/clicommands/HelloCommand.php

Here, `Hello` corresponds to the desired command, with a capital letter. The ending `Command` must ALWAYS be set.

**Example**

```php
<?php

namespace Icinga\Module\Training\Clicommands;

use Icinga\Cli\Command;

class HelloCommand extends Command
{
}
```

## Namespaces

* Namespaces help to separate modules from each other
* Each module gets a namespace, which equals the module name:

```
Icinga\Module\<Modulename>
```

* The first letter MUST be capitalized for each word
* For CLI commands, a dedicated namespace Clicommands is available

## Inheritance

All CLI commands MUST inherit the Command class in the namespace `Icinga\Cli`. This brings us a whole series of
advantages, which we will discuss later. It is important that our class name corresponds to the name of the file.
In our `HelloCommand.php` this would be the class `HelloCommand`.

## Command Actions

Each command can provide multiple actions. Any new public method that ends with `Action` automatically becomes a CLI
command action:

```php
<?php

namespace Icinga\Module\Training\Clicommands;

use Icinga\Cli\Command;

class HelloCommand extends Command
{
    public function worldAction()
    {
        echo "Hello World!\n";
    }
}
```

## Task 1

We create a CLI Command with an action, which is executed as follows, and generates the following output:

    icingacli training say hello

    Hello World!

## Bash Autocompletion

The Icinga CLI provides autocompletion for all modules, commands and actions. If you install Icinga Web from packages,
everything is already in the right place. For our test environment we will do this manually:

## Bash completion

    apt-get install bash-completion
    cp /usr/local/icingaweb2/etc/bash_completion.d/icingacli /etc/bash_completion.d/
    . /etc/bash_completion

If the input is ambiguous as in `icingacli mo`, then an appropriate help text will be displayed.

## Inline Documentation for CLI Commands

Inline comments can help documenting commands and their actions. The comments' text is immediately available on the CLI,
as a help text.

```php
/**
 * This is where we say hello
 *
 * The hello command allows us to be friendly to everyone
 * and their dog. That's how nice people behave!
 */
class HelloCommand extends Command
{
    /**
     * Use this to greet the world
     *
     * Greeting every single person would take some time,
     * so let's greet the whole world at once!
     */
    public function worldAction()
    {
        // ...
```

A few example combinations of how the help can be displayed:

    icingacli training
    icingacli training hello
    icingacli help training hello
    icingacli training hello world --help

The `help` command can be used before the other arguments or at any point as a parameter with `--`.

## Task 2

Create and test documentation for a `something` action for the `say` command in the `training` module!

## Command line parameters

It's possible to completely check, use and control command line parameters ourselves. Due to using inheritance,
the corresponding instance of `Icinga\Cli\Params` is already available in `$this->params`. The object has a `get()`
method, to which we can give the desired parameter and optionally a default value. Without default value we get
`null` if the corresponding parameter is not given.

```php
    /**
     * Say hello from somewhere
     *
     * Usage: icingacli training hello from --from <somewhere>
     */
    public function fromAction()
    {
        $from = $this->params->get('from', 'Nowhere');
        echo "Hello from $from!\n";
    }
```

### Example call

    icingacli training hello from --from Nuremberg
    icingacli training hello from --help
    icingacli training hello from

## Standalone parameters

It is not necessary to assign an identifier to each parameter. If you want, you can simply chain parameters.
Most conveniently, these are accessible via the `shift()` method:

```php
    /**
     * Say hello from somewhere
     *
     * Usage: icingacli training hello from <somewhere>
     */
    public function fromAction()
    {
        $from = $this->params->shift();
        echo "Hello from $from!\n";
    }
```

### Example call

    icingacli training hello from Nuremberg

## Shifting is fun

The `shift()` method behaves in the same way as you would expect from common programming languages. The first parameter
of the list is returned and subsequently removed from the list. If you call `shift()` several times in succession, all
existing standalone parameters are returned, until the list is empty. With `unshift()` you can undo such an action at
any time.

A special case is `shift()` with an identifier (key) as a parameter. So `shift('to')` would not only return the value
of the `--to` parameter, but also remove it from the params object, regardless of its position. Again, it is possible
to specify a default value:

```php
$person = $this->params->shift('from', 'Nobody');
```

Of course, this also works for standalone parameters. Since we have already used the first parameter of `shift()` with
the optional identifier (key), but still want to set something for the second (default value), we simply set the
identifier to null here:

```php
    public function fromAction()
    {
        $from = $this->params->shift(null, 'Nowhere');
        echo "Hello from $from!\n";
    }
```

### Example call

    icingacli training hello from Nuremberg
    icingacli training hello from --help
    icingacli training hello from

## API documentation

The Params class in the `Icinga\Cli` namespace documents other methods and their parameters. These are accessible in
the API documentation for convenience. A somewhat sophisticated IDE should be able to present it.

## Task 3

Extend the `say` command to support all of the following options:

    icingacli training say hello World
    icingacli training say hello --to World
    icingacli training say hello World --from "Icinga CLI"
    icingacli training say hello World "Icinga CLI"

## Exceptions

Icinga Web wants to promote clean PHP code. This includes, among other things, that all warnings generate errors.
Errors are thrown for error handling. We can just try it:

```php
    /**
     * This will always fail
     */
    public function brokenAction()
    {
        $this->fail('No way!');
    }
```

### Example Call

    icingacli training hello broken
    icingacli training hello broken --trace

## Exit codes

As we can see, the CLI catches all exceptions, and outputs nice and human readable error messages,
along with a colored indication of the error. The exit code in this case is always 1:

    echo $?

This allows reliable evaluation of failed jobs. Only the exit code 0 stands for successful execution.
Of course, everyone is free to use additional exit codes. This is done in PHP using `exit($code)`:

```php
echo "CRITICAL\n";
exit(2);
```

## Log Messages

You want colored output but throwing exceptions seems awkward? We have you covered here of course!
Just log a message and it will be appropriately colored according to the level:

```php
use Icinga\Application\Logger;

// ...

    /**
     * Log an error message
     *
     * Usage: icingacli training hello error <message>
     */
    public function errorAction()
    {
        Logger::error($this->params->shift(null, 'Lorem ipsum dolor sit amet'));
    }
```

### Example Call

    icingacli training hello error
    icingacli training hello error "The quick brown fox jumps over the lazy dog"

## Task 4

Extend the `say` command with an action for each of the log levels. (`error`, `warn` and `info`)
Figure out why the `info` level does not produce any output.

    icingacli training say error
    icingacli training say warning
    icingacli training say information

## Custom Colors

As we have just seen, the Icinga CLI can create colored output. The 'screen' class in the `Icinga\Cli` namespace
provides useful help functions. We can access it in our Command classes via `$this->screen`. This way the output
can be colored:

```php
echo $this->screen->colorize("Hello from $from!", 'lightblue') . "\n";
```

As an optional third parameter, the `colorize()` function can be given a background color. For the display of the
colors ANSI escape codes are used. If Icinga CLI detects that the output is NOT in a terminal/TTY, the output will
not contain any colors. This ensures that e.g. when redirecting the output to a file, no disturbing special characters
appear.

> To determine the terminal, PHP uses the POSIX extension. If this is not available,
> as a precaution the ANSI codes will not be used.

Other useful features in the Screen class are:

* `clear()` to clear the screen (used by `--watch`)
* `underline()` to underline text
* `newlines($count = 1)` to output one or more newlines
* `strlen()` to determine the character width without ANSI codes
* `center($text)` to output text centered depending on the screen width
* `getRows()` and `getColumns()` where possible, to determine the usable space
* `hasUtf8()` to query UTF8 support of the terminal

## Task 5

Our `hello` action in the `say` command should output the text in color and centered both horizontally and vertically.
We use `--watch` to flash the output alternately in at least two colors.

# Your own module in the web frontend

The **Web** in Icinga Web stands for its strongest suit, which we will have a look at now. And again,
**convention before configuration** applies. Built with the classic **MVC architectural pattern**,
there are controllers with actions and matching view scripts for markup and display.

## A first Controller

Every `action` in a `controller` automatically becomes a `route` in our web frontend. It looks something like this:

    http(s)://<host>/icingaweb2/<module>/<controller>/<action>

If we want to create another 'Hello World' for our training module, we need to create the basic directory for our
controllers first:

    mkdir -p training/application/controllers

Afterwards we add our controller. As you will probably have guessed already, it must be called `HelloController.php`,
and be in the Controller namespace of our module:

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

If we call the URL `training/hello/world` now, we get an error message:

    Server error: script 'hello/world.phtml' not found in path
    (/usr/local/icingaweb2-modules/training/application/views/scripts/)

Conveniently, it immediately tells us what we need to do next.

## Create a view script

The corresponding base directory is still missing. Since we create a view script in a dedicated file per 'action',
there is one directory per 'controller':

    mkdir -p training/application/views/scripts/hello

The view script is then just like the 'action', so `world.phtml`:
    
```php
<h1>Hello World!</h1>
```

That's it, our new URL is now available. We can now use the full scope of our module and style it accordingly.
And we can also use a few predefined elements. Two important classes are e.g. `controls` and `content`,
for header elements and the page content.

```php
<div class="controls">
<h1>Hello World!</h1>
</div>

<div class="content">
Some content...
</div>
```

This automatically gives even spacing to the page margins, and also makes it so that when scrolling down,
the `controls` stay stationary, while the `content` scrolls. Of course, this will not be noticeable until
we fill our module with more content.

## Menu entries

Menu entries in Icinga Web can be personalized and/or predefined by the administrator. They can also be provided
by modules. What we see here is a global configuration that is located in the base directory of your own module
in `configuration.php`:

```php
<?php

$this->menuSection('Training')
     ->add('Hello World')
     ->setUrl('training/hello/world');
```

### Icons for menu entries

In order to make our menu item look even better, we will add a little icon in front of it:

```php
<?php

$trainingMenu = $this->menuSection('Training')
     ->setIcon('thumbs-up');

$trainingMenu->add('Hello World')
     ->setUrl('training/hello/world');
```

To have a look at the available icons, we can activate the `doc` module under `Configuration`/`Modules`.
If the module is active, you can find the icon list under `Documentation`/`Developer - Style`.
These icons have been embedded in a font, which allows them to be styled the same as text.

Alternatively, you can still use classic icons (.png etc) if you wish. This is especially useful, if you want to use
a special icon (for example, a company logo) for your module, which is not included in the official Icinga Icon font:

```php
$trainingMenu->setIcon('img/icons/success.png');
```

## Adding images

If you would like to use your own images in your module, you can simply provide them under `public/img`:

    mkdir -p public/img
    wget https://icinga.com/wp-content/uploads/2016/02/icinga_icon.png
    mv icinga_icon.png public/img/

Our images are immediately accessible in the web interface, the URL pattern is as follows:

    http(s)://<icingaweb2>/img/<module>/<picture>

In our case that would be: http://localhost/img/training/icinga_icon.png. This can also be used in our view scripts
in the same way. Instead of creating an img tag (which of course would be possible) we use one of the many practical
view helpers:

```php
<div class="content">
<?= $this->img('img/training/icinga_icon.png', array('title' => 'Icinga Icon')) ?> Some Content...
</div>
```

## Task 1

Create the routes `training/hello/test` and `training/say/hello` and add an additional menu item for each.
Look for a nicer icon for our training module on the internet and add it to the menu entry.

## Dashboards

Before we try to tackle more complex issues we will first provide our route as a default dashboard.
This can also be done in `configuration.php`:

```php
<?php
$this->dashboard('Training')->add('Hello', 'training/hello/world');
```

# We need data!

With our web routes being all set up, we want to do something more meaningful with them. An application can look
oh so dashing, but without useful content, it will quickly get boring. The usual workflow in an MVC environment
looks like this: The `controller` gets its data with the aid of its `model`, and then passes it on to the `views`
for displaying.

## Fill our view with data

The controller provides access to our view with `$this->view`. This way it can be populated easily:

```php
    public function worldAction()
    {
        $this->view->application = 'Icinga Web';
        $this->view->moreData = [
            'Work'   => 'done',
            'Result' => 'fantastic'
        ];
    }
```

We will now expand our view script and display the submitted data:

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

## Task 2

The contents of our module directory should be shown in form of a table under `training/list/files`.
* Note: with `$this->Module()->getBaseDir()` we can access our module directory
* More about opening directories in the [PHP documentation](https://www.php.net/manual/en/function.opendir.php)

# But please with style!

Although it is not directly related to our topic, one thing stands out: our table doesn't exactly look very flashy
(yet). To improve its looks, we can easily put CSS to our module. We create a suitable directory, the naming follows
the same scheme as before:

    mkdir public/css

We then add our CSS/LESS instructions in the file `module.less`. Less is a CSS extension, which adds a variety of
functions, more can be found at [lesscss.org](https://lesscss.org/). LESS also accepts conventional CSS. The nice
thing about Icinga Web is, that there is no need to worry about whether ones CSS will influence other modules - or
Icinga Web itself.

So we can easily define the following, without *breaking* foreign tables:

    table {
        width: 100%;
    }

    th {
        width: 20%;
        text-align: right;
        line-height: 2em;
        padding-right: 2em;
    }

When we watch the requests in our browser's developer tools, we can see that Icinga Web loads css/icinga.min.css as
the only CSS file. We can also load css/icinga.css to conveniently view what Icinga Web has turned CSS code into:

    .icinga-module.module-training table {
      width: 100%;
    }
    .icinga-module.module-training th {
      width: 20%;
      text-align: right;
      line-height: 2em;
      padding-right: 2em;
    }

Prefixes ensure that our CSS only applies to the containers, in which our module displays its contents.

## Useful CSS classes

Icinga Web 2 provides a set of CSS classes that make our job easier. The class `common-table` is used for our default,
list like, tables, `name-value-table` for name/value pairs where the identifier is displayed as `th` on the left and
the corresponding value in a `td` on the right. Also useful is `table-row-selectable` - this changes the behavior of
the table. In combination with `common-table`, the whole line is highlighted when you hover over it. If you click
somewhere, the first link of the line will be considered clicked.

# Real data, all cleaned up

As we stated earlier, a module only becomes interesting with real data. What we have done wrong, however, is that
our controller defines the data itself. That is not a good practice, and might cause some problems - for example
if we want to use the data on the CLI.

## Our own library

We are going to create a new directory for the library we want to use in our module,
following the scheme `library/<Modulename>`. In our case:

    mkdir -p library/Training

For our module we will use the namespace `Icinga\Module\<Modulename>`. The module name's first letter must be
uppercase. (in the directory name and the namespace) Icinga Web will automatically search for any namespace
created within `Training` in the newly created directory. There are some exceptions to that rule:

 * `Clicommands`
 * `Controllers`
 * `Forms`

Any sub-directory of `library/Training` represents its own namespace. For example, `library/Training/FileSystem`
uses the namespace `Icinga\Module\Training\FileSystem` and `library/Training/FileSystem/FileInfo` does use
`Icinga\Module\Training\FileSystem\FileInfo`.

A class, that implements the solution for the last exercise, might be in `library/Training/Directory.php`
and look like this:

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

            $result[] = (object) [
                'name' => $file->getFilename(),
                'path' => $file->getPath(),
                'size' => $file->getSize(),
                'type' => $file->getType()
            ];
        }

        return $result;
    }
}
```

An important detail is that the filename is the same as the class name. If these differ, the class fails to load.

Our controller can now retrieve the data via this class:

```php
// ...
use Icinga\Module\Training\Directory;

class FileController extends Controller
{
    public function listAction()
    {
        $this->view->files = Directory::listFiles($this->Module()->getBaseDir());
    }
}
```

## Task 3

Put this, or a comparable class, in your module. Provide a view script, which displays a list of the individual
files. Use `$this->escape()` in the view script, where you can't be sure the data comes from a safe source.
(for example, filenames)

# Parameter handling

So far we have not added any parameters to our routes. But that's just as easy. Like on the command line,
Icinga Web provides simple access to `Params`. Access is as follows:

```php
<?php
$file = $this->params->get('file');
```

`shift()` and the like are available as well.

## Task 4

At `training/file/show?file=<filename>` additional information about the desired file can be displayed.
You can display owners, permissions, last change and mime-type - but it is also quite simple enough to
display name and size in a more orderly fashion.

## Related links

In our file list we now want to link from each file to the corresponding detail area. To avoid problems
with parameter escaping, we use the known helper `qlink`:

```php
<td><?= $this->qlink(
    $file->name, // text to be displayed
    'training/file/show', // route to use
    ['file' => $file->name] // URL parameters
) ?></td>
```

If we now click on a file in our list, we get the corresponding details displayed. But there is a more comfortable
way to do this. Just try putting `data-base-target="_next"` in the content-div:

    <div class="content" data-base-target="_next">

That way, we are using the multi column layout of Icinga Web for the first time - and that without much extra effort!

# URL handling

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
functionality. This can be conveniently managed in the controllers:

```php
    public function listAction()
    {
        // ...

        $this->setAutorefreshInterval(10);
    }
```

## Task 5

Our file list should update automatically, the detail information panel should as well. Show the last modification
date of a file (`$file->getMtime()`) and use the `timeSince` helper to display the time. Change a file on the hard
drive and see what happens. How can that be explained?

# Configuration

Those who develop a module would most likely want to be able to configure it too. The configuration for a module is
stored at `/etc/icingaweb2/modules/<modulename>`. Everything found in the `config.ini`, is accessible in the
controller as follows:

```php
    public function configAction()
    {
        $config = $this->Config();

        /*
        [section]
        entry = "value"
        */
        echo $config->get('section', 'entry');

        // Returns 'default' because 'noentry' does not exist:
        echo $config->get('section', 'noentry', 'default');

        // Reads from the special.ini instead of the config.ini:
        $special = $this->Config('special');
    }
```

## Task 6

The base path for the list controller of our training module should be configurable.
If no path is configured, we continue to use our module directory.

# Translations

For a detailed description of the translation options, we will check the
[documentation for the `translation` module](https://icinga.com/docs/icinga-web/latest/modules/translation/doc/03-Translation/#module-translation-introduction).

# Using Icinga Web logic in third party software?

With Icinga Web we want to make the integration of third party software as easy as possible.
We also want to make it easy for others to use Icinga Web logic in their software.

The following call in any PHP file is enough to achieve this:

```php
<?php

require_once '/usr/local/icingaweb2/library/Icinga/Application/EmbeddedWeb.php';
Icinga\Application\EmbeddedWeb::start('/usr/local/icingaweb2');
```

Done! No authentication, no bootstrapping of the full web interface. But any library code can be used.

## Task 7

Create an additional PHP file that embeds Icinga Web. Then use the directory handling class from your training module.

# The Finish Line

So, looks like you made it! Now you learned the basics on module development for Icinga Web - for the rest: just try
it out yourself! You can get some more help by looking at existing modules on [Icinga Exchange](https://exchange.icinga.com/)
and for inspiration you can also come to our [Icinga Events](https://icinga.com/community/events/).

Have fun tinkering and happy hacking with Icinga Web!!1
