# Translations

Icinga Web 2 provides localization out of the box - for itself and the core modules.

This is done via the PHP library `ipl\i18n`, which provides a translation suite using PHP's native gettext extension. Hint: 'i18n' is an abbreviation for 'internationalization'.

The library provides the PHP trait `Translation` that enables internationalization via the `translate()` method.

The Controllers we have seen already have this trait:

```php
<?php

class ExampleController extends Controller
{
    public function indexAction()
    {
        $this->view->title = $this->translate('Hello World');
    }
}
```

The `Hello World` string will be translated if a translation is available.
Otherwise it will remain as it is.

To enable internationalization in any custom class we can simply add the `Translation` trait:

```php
<?php

namespace Icinga\Module\Training;

use DirectoryIterator;

class Directory
{
    use Translation;
```

# Translation Files

Icinga Web uses the UNIX standard `gettext` tool to perform internationalization, this means translation files are supplied via PO and MO files.

PO files are human-readable files containing message IDs and their translations for a specific language. Example:

```
# cat application\locale\de_DE\LC_MESSAGES

msgid "Hello World"
msgstr "Hallo Welt"
```

The `msgid` in the PO file is what we use in the `translate()` method.

PO files are transformed into MO files, that are meant to be read by programs.

# Creating Translations

With the `translation` module enabled the Icinga Web CLI offers tooling to help create internationalization:

```bash
icingacli translation refresh module training de_DE
```

This will create a boilerplate file to get you started:

```bash
cat modules/training/application/locale/de_DE/LC_MESSAGES/training.po

# Icinga Web 2 Training module.
#, fuzzy
msgid ""
msgstr ""
"Project-Id-Version: Training Module\n"
```

PO/MO files are placed in:

* `application/locale/<language>_<region>/LC_MESSAGES/<modulename>.po`
* `application/locale/<language>_<region>/LC_MESSAGES/<modulename>.mo`

Both of which need to be shipped with the module's PHP code.

Further information can be found here:

* [gettext Documentation](https://www.gnu.org/software/gettext/)
* [Icinga Web Documentation](https://icinga.com/docs/icinga-web/latest/modules/translation/doc/03-Translation)
