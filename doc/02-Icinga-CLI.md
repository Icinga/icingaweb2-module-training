# The Icinga CLI

The Icinga CLI was designed to provide most of the application logic in Icinga Web, and its modules, on the
commandline. Example use cases are:

* Cronjobs
* Plugins
* Data import and export
* Housekeeping tools
* smaller services (like the development web server)

## CLI Commands

The structure of the CLI commands is:

```bash
icingacli <module> <command> <action>
```

Creating a CLI command is very easy.
Files in the directory `application/clicommands` will automatically create CLI commands, whose names correspond to the desired command:

```bash
cd /usr/local/icingaweb2-modules/training

mkdir -p application/clicommands

vim application/clicommands/HelloCommand.php
```

Here, `Hello` corresponds to the desired command, with a capital letter. The ending `Command` MUST always be set.

```php
<?php

namespace Icinga\Module\Training\Clicommands;

use Icinga\Cli\Command;

class HelloCommand extends Command
{
}
```

All CLI commands MUST inherit the `Command` class in the namespace `Icinga\Cli`.

The class name `HelloCommand` MUST correspond to the file name.
In our `HelloCommand.php` this would be the class `HelloCommand`.

## Namespaces

* Namespaces help to separate modules from each other
* Each module gets a namespace, which equals the module name:

```php
Icinga\Module\<Modulename>
```

* The first letter MUST be capitalized for each word
* For CLI commands, a dedicated namespace Clicommands is available

## Command Actions

Each command can provide multiple actions. Any new public method that ends with `Action` automatically becomes a CLI action:

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

This creates a CLI `world` action for the `hello` command, which is executed as follows:

```bash
icingacli training hello world

Hello World!
```

### Side note: Bash autocompletion

The Icinga CLI provides autocompletion for all modules, commands and actions.

If you install Icinga Web from packages, everything is already in the right place.

For our test environment we will do this manually:

```bash
apt-get install -y bash-completion
cp /usr/local/icingaweb2/etc/bash_completion.d/icingacli /etc/bash_completion.d/

. /etc/bash_completion
```

If the input is ambiguous as in `icingacli mo`, an appropriate help text is displayed.

## Inline Documentation for CLI Commands

Inline comments can help documenting commands and their actions.
This text is immediately available on the CLI, as a help text.

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

```bash
icingacli training
icingacli training hello

icingacli help training hello
icingacli training hello world --help
```

The `help` command can be used before the other arguments or as a parameter with `--help`.

### Training Task: 1

1. Create a `say` CLI command with a `something` action
2. Create documentation for the `something` action

## Command line parameters

Command line parameters are available in `$this->params`, which is an instance of `Icinga\Cli\Params`.

This object has a `get($key, $default = null)` method, that returns the value of the given parameter. The method can also return a default value if the parameter is not found.

```php
    /**
     * Say hello from somewhere
     *
     * Usage: icingacli training hello from --where <somewhere>
     */
    public function fromAction()
    {
        $from = $this->params->get(where, 'nowhere');
        echo "Hello from $from!\n";
    }
```

Examples:

```bash
icingacli training hello from --where Nuremberg
icingacli training hello from --help
icingacli training hello from
```

### Standalone parameters

It is not necessary to assign an identifier to each parameter, you can simply chain parameters.

These are accessible via the `shift()` method:

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

The `shift()` method behaves the same way as in other programming languages: the first parameter of the list is returned and subsequently removed from the list.

If you call `shift()` several times in succession, all existing standalone parameters are returned, until the list is empty.

With `unshift()` you can undo such an action at any time.

```
icingacli training hello from Nuremberg
```

### Shifting is fun

A special case is `shift()` with an identifier (key) as a parameter.

So `shift('to')` would not only return the value of the `--to` parameter,
but also remove it from the params object, regardless of its position.

Again, it is possible to specify a default value:


```php
$person = $this->params->shift('from', 'nobody');
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

Examples:

```bash
icingacli training hello from Nuremberg
icingacli training hello from --help
icingacli training hello from
```

### Side note: API documentation

The `Params` class in the `Icinga\Cli` namespace documents other methods and their parameters. These are accessible in
the API documentation.

### Training Task: 2

1. Extend the `say` command to support all of the following options:

```bash
icingacli training say hello World
icingacli training say hello --to World
icingacli training say hello World --from "Icinga CLI"
icingacli training say hello World "Icinga CLI"
```

## Exceptions

Icinga Web wants to promote clean PHP code. This includes, among other things, that all warnings generate errors.

For handling errors `Exception` are thrown.

```php
    /**
     * This will always fail
     */
    public function brokenAction()
    {
        $this->fail('No way!');
    }
```

All actions support the `--trace` parameter to include a trace of the error. Examples:

```bash
icingacli training hello broken
icingacli training hello broken --trace
```

### Side note: Exit codes

As we can see, the CLI catches all exceptions, and prints human readable error messages,
along with a colored indication of the error.

The exit code in this case is always 1:

```bash
echo $?
```

Only the exit code 0 stands for successful execution.

This allows reliable evaluation of failed jobs.

Of course, everyone is free to use additional exit codes. This is done in PHP using `exit($code)`:

```php
echo "CRITICAL\n";
exit(2);
```

## Log Messages

We can use the `Icinga\Application\Logger` class to provide logging capabilities to our module.

A Logger has multiple static functions corresponding to common log levels.

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
        Logger::error($this->params->shift(null, 'Something went wrong'));
    }
```

The `Logger` class uses its `$writer` to output the messages. Icinga Web provides several predefined `LogWriter` classes in `Icinga\Application\Logger\Writer`.

Examples:

```bash
icingacli training hello error
icingacli training hello error "The quick brown fox jumps over the lazy dog"
```

### Training Task: 3

1. Extend the `say` command with an action for each log level (`error`, `warning`, `info`, `debug`).
2. Figure out why the `info` level does not produce any output.

```bash
icingacli training say error
icingacli training say warning
icingacli training say information
icingacli training say debug
```

## Custom Colors

The `Icinga\Cli\Screen` class provides functions to create colored output.

Our Command class can use this via `$this->screen` to adjust colors:

```php
echo $this->screen->colorize("Example", 'lightblue') . "\n";
```

As an optional third parameter, the `colorize()` function can be given a background color. For the display of the colors ANSI escape codes are used.

Hint: if Icinga CLI detects that the output is NOT in a terminal/TTY, the output will not contain any colors.

This ensures that no breaking characters appear when redirecting the output to a file.

> To determine the terminal, PHP uses the POSIX extension. If this is not available,
> as a precaution the ANSI codes will not be used.

Other useful features in the `Screen` class are:

* `clear()` to clear the screen (used by `--watch`)
* `underline()` to underline text
* `newlines($count = 1)` to output one or more newlines
* `strlen()` to determine the character width without ANSI codes
* `center($text)` to output text centered depending on the screen width
* `getRows()` and `getColumns()` where possible, to determine the usable space
* `hasUtf8()` to query UTF8 support of the terminal

### Training Task: 4

1. The `hello` action in the `say` command should output the text in color and centered both horizontally and vertically
2. Use the `--watch` to flash the output alternately in two colors
