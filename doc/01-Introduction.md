# Extending Icinga Web

Welcome! Glad to see that you are here to write your first Icinga Web module. Icinga Web makes getting started as easy
as possible. Over the next few hours we will discover how fun tinkering with Icinga Web can be, with a series of
practical examples.

# Table of Contents

* [Introduction](#preparation)
* [The Icinga CLI](02-Icinga-CLI.md)
* [Icinga Web Module](05-Web-Module.md)
* [Icinga PHP Library](10-The-Icinga-PHP-Library.md)

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

# Icinga Web Architecture

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

Icinga Web follows the paradigm 'convention before configuration'. Basically, in Icinga Web you only have to configure
paths for special cases. It is usually enough to just save a file, in the right place.

An extensive module could have approximately the following structure:

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

# Preparation

For the development we require PHP and the following PHP modules: `php-gd php-intl php-curl php-xml php-json`.

Icinga builds up-to-date snapshots daily, for a wide range of operating systems, available at [packages.icinga.com](https://packages.icinga.com/). But for our training we will use the Git repository directly.

## Icinga Web from Source

To get started, we need Icinga Web. For installing Icinga Web please check the [installation from source chapter](https://icinga.com/docs/icinga-web/latest/doc/02-Installation/07-From-Source/) in the documentation.

This also requires the Icinga PHP Library (ipl) and the Icinga PHP Thirdparty libraries (includes the Zend Framework).

Icinga Web provides an internal web server for development:

```bash
/usr/share/icingaweb2/bin/icingacli web serve
```

The web interface is now available at:

```bash
http://localhost/setup
```

### Side note: Manage multiple module paths

Those who always work with the latest version, or want to switch between Git branches safely, usually do not
want to have to change files in their working copy.

Therefore, it is recommended to use several module paths in parallel
from the start.

This can be done in the system settings or in the configuration at `/etc/icingaweb2/config.ini`:

```
[global]
module_path = "/usr/local/icingaweb2-modules:/usr/local/icingaweb2/modules"
```

# Write your own Icinga Web module

## Naming Icinga Web modules

Once you know what the module is going to do, the hardest task is often choosing a good name.

The name should not be too complicated, because we will use it in PHP namespaces, directory names, and URLs. Your own (company) name is often a good starting point.

It should consist only of **alphanumeric characters** and **must not start with a number**. Examples:

* [director](https://github.com/Icinga/icingaweb2-module-director)
* [jira](https://github.com/Icinga/icingaweb2-module-jira)
* [cube](https://github.com/Icinga/icingaweb2-module-cube)
* [x509](https://github.com/Icinga/icingaweb2-module-x509)

For this training we will simply use the name `training`.

## Create and activate a new module

```bash
mkdir -p /usr/local/icingaweb2-modules/training

icingacli module list installed
icingacli module enable training
```
