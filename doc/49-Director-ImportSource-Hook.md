# Director ImportSource Hook

The Icinga Director has the functionality to pull objects from external sources and import them as Icinga objects.

The interface to build your own ImportSource is the [ImportSourceHook](https://github.com/Icinga/icingaweb2-module-director/blob/master/library/Director/Hook/ImportSourceHook.php).

The following functions form the basic logic:

```php
<?php

namespace Icinga\Module\Training\ProvidedHook\Director;

use Icinga\Module\Director\Hook\ImportSourceHook;
use Icinga\Module\Director\Web\Form\QuickForm;

class ImportSource extends ImportSourceHook
{

    /**
     * @return string 
     */
    public function getName()
    {
        // Define the name that will be displayed in the dropdown of available ImportSources
        return "Custom CMDB Import";
    }

    /**
     * @param QuickForm $form
     * @return void
     */
    public static function addSettingsFormFields(QuickForm $form)
    {
        // (This function is optional)
        // In most cases, further arguments are required to define e.g. URLs of an API, auth, etc.
        // This can be done here. We just need to add form elements via the Icinga Director QuickForm

        // Note: This is not used here, but to have an example it is added to the code

        $form->addElement('text', 'endpoint', [
            'label' => 'API Endpoint',
            'required' => true,
            'description' => 'API Endpoint to fetch data from',
        ]);

        // After submitting the form you can get the setting via `$this->('endpoint');`
    }

    /**
     * @return iterable
     */
    public function fetchData()
    {
        // The fetch data function is the primary function that is used.
        // It should return an iterable that provides simple php objects with public properties as columns. (e.g. `(object) ['foo' => 'bar'])`
        return [
            (object) ['host' => 'host-1', 'ip' => '127.0.0.1'],
            (object) ['host' => 'host-2', 'ip' => '127.0.0.2'],
        ];
    }

    /**
     * @return array
     */
    public function listColumns()
    {
        // Returns a list of columns used in the fetchData() function.
        return ["host", "ip"];
    }
}
```

This example is very simple and returns the objects hardcoded. In an advanced ImportSource, they would of course be fetched from an external source via APIs or similar, processed, and passed to the Director in the needed format.
