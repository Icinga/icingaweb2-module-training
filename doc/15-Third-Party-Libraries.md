# Third Party Libraries

While the PHP standard library is quite extensive sometimes third party libraries are required.
This section will show how to include third party code in an Icinga Web module.

## module.info

The `module.info` file contains metadata about a Icinga Web module. This information is available in the Icinga Web module overview.

Within the file we can use the following fields:

* `Module` the module's name
* `Version` the module's current version
* `Requires` the module's requirements
  * `Libraries` a comma separated list of required PHP libraries
  * `Modules` a comma separated list of required Icinga Web modules
* `Description` a detailed description of the module

Example:

```
Module: my-module
Version: 0.1.0
Requires:
  Libraries: icinga-php-library (>=0.12.0), icinga-php-thirdparty (>=0.11.0)
  Modules: monitoring (>=2.9.0)
Description: My Example Module
 This module provides trainings and tutorials to get you started
```

This is also where we would specify required libraries or modules and their versions.

## The Icinga PHP Third Party Project

The [Icinga PHP 3rd party](https://github.com/Icinga/icinga-php-thirdparty) project bundles all 3rd party PHP libraries used by Icinga Web products.
These are some of them:

* [jQuery](https://github.com/components/jquery)
* [Less.php](https://github.com/wikimedia/less.php)
* [ReactPHP Modules](https://github.com/reactphp)
* [HTML Purifier](https://github.com/ezyang/htmlpurifier)
* [Guzzle HTTP Client](https://github.com/guzzle/guzzle)
* [Dompdf](https://github.com/dompdf/dompdf)
* [Parsedown](https://github.com/erusev/parsedown)
* [Événement](https://github.com/igorw/evenement)
* [php-diff](https://github.com/jfcherng/php-diff)
* [Predis](https://github.com/predis/predis)
* [PSR Log](https://github.com/php-fig/log)
* [ramsey/uuid](https://github.com/ramsey/uuid)
* [brick/math](https://github.com/brick/math)

Refer to their respective documentation to see how to use them within your Icinga Web module.

With the Icinga PHP 3rd party library installed we can use the above mentioned libraries simply like this:

```php
use GuzzleHttp\Client;
use Ramsey\Uuid\Guid\Guid;
```

## The Icinga Web Incubator

The [Icinga Web Incubator](https://github.com/Icinga/icingaweb2-module-incubator) ships bleeding edge libraries useful for Icinga Web modules.

Each library is namespaced by their respective creator. This means you would import and use an incubator library like this:

```php
use gipfl\Json\JsonString

$j = JsonString::decode($json);
```

Please be aware that all incubator libraries are experimental and thus prone to change.

## Custom/Third Party CSS and JavaScript

Icinga Web provides several directories for loading custom/third party CSS and JavaScript code.

    .
    └── training                Basic directory of the module
        ├── application
        ├── configuration.php   Deploy menu, dashlets, permissions
        ├── module.info         Module Metadata
        ├── public
        │   ├── css             Own CSS Code
        │   ├── img             Own Images
        │   └── js              Own JavaScript

### CSS

The `module.less` file in the directory `public/css` is used for adding custom CSS.

```
vim public/css/module.less

.myclass {
  color: black;
}
```

Additional CSS/Less files from the `public/css` directory can be loaded via the `configuration.php` file:

```php
$this->provideCssFile(more.less');
```

This directory is also where you would place third party CSS code, either minified or unminified, since Icinga Web will minify things for you.

### JavaScript

The `module.js` file in the directory `public/js` is used for adding custom JavaScript.

Icinga Web will add this code to its `js/icinga.min.js`, the unminified version of this can be found at `js/icinga.js`.

```
vim public/js/module.js

(function(Icinga) {
    alert("Hello World");
}(Icinga));
```

Additional JavaScript files from the `public/js` directory can be loaded via the `configuration.php` file:

```php
$this->provideJsFile('action-list.js');
```

This directory is also where you would place third party JavaScript. A good practice is to use a `vendor` directory within `public/js` for third party code.
