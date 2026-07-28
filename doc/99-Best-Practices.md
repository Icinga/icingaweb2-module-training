# Best practices for writing Icinga Web Modules

This documents provides a concise list of best practices for writing Icinga Web Modules.

* The module.info should declare all dependencies (and their versions) of a module.
* The IPL and Icinga-PHP-Thirdparty cover many use cases, these libraries should be used instead of custom implementations.
* Views scripts in HTML must be avoided, instead use the ipl-html and ipl-web, which lets you write HTML in PHP and an object oriented way.
* All user-facing text should be wrapped with a translation method from `ipl\I18n\Translation`. Either `$this->translate()` or `$this->t()`.
* Zend import must be avoided, assume there is an idiomatic Icinga Web/IPL way instead.
* Controllers should use the class `ipl\Web\Compat\CompatController`.
* Forms should use the class `ipl\Web\Compat\CompatForm` or `ipl\Html\Form`.
* Forms should validate user input with `ipl\Validator`.
* HTTP requests should use GuzzleHTTP provided by Icinga-PHP-Thirdparty.
* JavaScript code can use jQuery provided by Icinga Web, but should use native alternatives if available.
* All code should work with Icinga Web's strict CSP

## Database

* Database connections should use an Icinga Web Resource for the connection configuration.
* Database queries should use the ipl-orm and ipl-sql. An ORM approach is recommended.
* Database migrations should use the DbMigrationHook.
* Schema files use the `schema/` directory, migratrions the in `schema/mysql-upgrades/` and `schema/pgsql-upgrades/`.

## Module directory structure

General:

* `module.info` contains metadata, version and dependencies
* `run.php` is used to register hooks
* `doc/` is the directory for Markdown documentation

The application directory:

* `application/clicommands` contains all CLI Commands.
* `application/controllers` contains all controllers.
* `application/forms` should be avoided,instead use `library/<Module Name>/Web` for Forms
* `application/views` should be avoided, instead use IPL HTML.

The library directory:

* `library/<Module Name>/Common` contains common components such as Database connections and Authentication.
* `library/<Module Name>/Widget` contains all IPL HTML Elements.
* `library/<Module Name>/Web` contains custom Controllers and Forms
* `library/<Module Name>/Model ` contains all ORM models for the module.
* `library/<Module Name>/Hook` contains all Hooks this module exposes for other modules.
* `library/<Module Name>/ProvidedHook` contains all Hooks from other modules this module implements. Use a subdirectory for each module that provides the hook.

The public directory:

* `public/css` contains all CSS or LESS for the module.
* `public/js` contains all JavaScript for the module.
