# Working with Forms

HTML Forms allow us to manipulate data. To create forms for Icinga Web we use or extend the `Form` class.

All custom form classes should be created in `application/forms`.

## ipl\Html\Form

`ipl\Html\Form` is a newer implementation and does not depend on `Zend_Form`, which older implementations did.

Similar to the CompatController the `ipl\Web\Compat\CompatForm` class acts as a compatibility layer between Icinga Web and the IPL.

These classes are generally used when you want to create forms.

Useful information about the class:

* Form is a `BaseHtmlElement` and has the trait `FormElements`
* By default, it uses the HTTP **POST** method to submit data. Can be adjusted: `getMethod()/setMethod()`
* The submission URL can be adjusted: `setAction()/getAction()`

```php
use ipl\Html\Form;

$form = new Form();
$form->setAction('/your/url');
$form->addElement('text', 'name', ['label' => 'Your name']);

$form->populate([
    'name'     => 'John Doe',
    'customer' => '5'
]);

$form->getElement('customer')->setValue('4');
$form->getValues();
```

The method `addElement($typeOrElement, $name = null, $options = null)` is how we can add new elements to the form.

This method either takes the type of the element as string or an `ipl\Html\FormElement`.


```php
$form->addElement('checkbox', 'mycheckbox', ['label' => 'A checkbox']);
$form->addElement('select', 'myselect', ['label' => 'A select']);
$form->addElement(number, 'mynumber', ['label' => 'A number']);
```

```php
use ipl\Html\FormElement\TextElement;

$nameElement = new TextElement('name', ['class' => 'important']);

$form->addElement($nameElement);
```

## Icinga\Web\Form

`Icinga\Web\Form` is an older implementation which mainly used for providing configurations tabs.

`Icinga\Forms\ConfigForm` extends this class and provides standard functionality for configuration forms.

These classes are generally used when you want to work with `.ini` based data.

# Updating the Table of Assets

## Creating an AssetForm

First we create an AssetForm in `application/forms/AssetForm.php`.

In its constructor we will pass the database connection, so that we can update the data when the submit button is pressed.

Within the `assemble()` method we add the required HTML elements.

```php
<?php

namespace Icinga\Module\Training\Forms;

use ipl\Sql\Connection;
use ipl\Web\Compat\CompatForm;

class AssetForm extends CompatForm
{
    private $db;
    protected array $usersByName = ['- Please choose -'];

    public function __construct(Connection $db, array $usersByName)
    {
        $this->db = $db;
        // Used to show the user names in the select element
        $this->usersByName = array_merge($this->usersByName, $usersByName);
    }

    protected function assemble(): void
    {
        $this->addElement('text', 'asset_id', ['label' => 'ID', 'readonly' => true]);
        $this->addElement('text', 'serial', ['label' => 'Serial No.']);
        $this->addElement('text', 'manufacturer', ['label' => 'Manufacturer']);
        $this->addElement('text', 'type', ['label' => 'Type']);
        $this->addElement('select', 'assigned', [
            'label'   => 'Assigned To',
            'options' => $this->usersByName,
        ]);

        $this->addElement('submit', 'submit', [
            'label' => 'Submit'
        ]);
    }
}
```

The Form class has various methods to work with input.

The `getValues()` and the `getValue()` method can be used to retrieve data from an input element.

Often you want to preset some values. This is possible either for the whole form via `populate($values)` or for single element via `setValue($value)`.

The `onRequest()` method is called when the Form is requested.

Once the submit button is pressed, the following happens:

* The `hasBeenSubmitted()` method is used to determine if the submit button has been pressed. If you have multiple submit buttons (save, clear, delete) you can override the function to implement this logic
* The `isValid()` method is used to validate the given input data
* The `onSuccess()` method is called once the form has been validated and submitted. This is where the main functionality happens. If this fail the Form's `onError()` method is called.

We can see all this happening when we have a look that the Form's `handleRequest()` method.
This is also the function we need to call to handle the requests, we simply ask the Controller for the request and pass it into the method:

```php
handleRequest($this->getServerRequest())
```

We can now add the `onSuccess()` method to the `AssetForm` class. This method will read the current values and send them to the database.

```
    protected function onSuccess()
    {
        $asset = [
            'user_id'      => $this->getValue('assigned'),
            'serial_no'    => $this->getValue('serial'),
            'manufacturer' => $this->getValue('manufacturer'),
            'type'         => $this->getValue('type')
        ];
        // Update the asset with the given ID
        $this->db->update('asset', $asset, ['id = ?' => $this->getValue('asset_id')]);
    }
}
```

## Creating the AssetController

Now we add an `AssetController` that will present the `AssetForm` given the serial number.

We have some duplicated code to get the database connection here. This could be placed in `library/Training/Common`.

```php

namespace Icinga\Module\Training\Controllers;

use Icinga\Web\Notification;

use Icinga\Module\Training\Forms\AssetForm;
use Icinga\Module\Training\Model\Asset;
use Icinga\Module\Training\Model\User;
use ipl\Html\Html;
use ipl\Sql\Connection;
use ipl\Stdlib\Filter;
use ipl\Web\Compat\CompatController;

class AssetController extends CompatController
{
    /** @var Connection */
    protected $db;

    /**
     * Get the database connection
     *
     * @return Connection
     */
    protected function getDb()
    {
        if ($this->db === null) {
            $this->db = new Connection([
                'db' => 'sqlite',
                'dbname' => $this->Module()->getConfigDir() . '/assets.sqlite'
            ]);
        }

        return $this->db;
    }

    public function indexAction()
    {
        $serial = $this->params->get('serial');

        $asset = Asset::on($this->getDb())
               ->with('user')
               ->filter(Filter::equal('asset.serial_no', $serial))
               ->first();

        $users = [];
        $userQuery = User::on($this->getDb())->columns('name');
        foreach ($userQuery as $u) {
            $users[] = $u->name;
        }

        $this->addContent(Html::sprintf('%s', Html::tag('h2', $serial)));

        $this->addTitleTab('Asset details');

        $formData = [
            'serial'       => $serial,
            'asset_id'     => $asset->id,
            'type'         => $asset->type,
            'manufacturer' => $asset->manufacturer,
            'type'         => $asset->type,
            'assigned'     => $asset->user->id,
        ];

        $form = new AssetForm($this->getDb(), $users);
        $form->populate($formData);

        $form->on(AssetForm::ON_SUCCESS, function () {
            Notification::success("Asset updated");
            $this->redirectNow('__CLOSE__');
        });

        $form->handleRequest($this->getServerRequest());
        $this->addContent($form);
    }
}
```

Let's have a closer look at the final section. Since the `ipl\Html\Form` also uses the `Events` trait it can emit and handle events. This is what we see here:

```php
$form->on(AssetForm::ON_SUCCESS, function () {
    Notification::success("Asset updated");
    $this->redirectNow('__CLOSE__');
});
```

The AssetForm will emit the ON_SUCCESS signal (one of the predefined signal, but you can also add your own), on which we can call a function.

We can use this to notify the user about the condition of the request and to tell the controller to `__CLOSE__` the current tab.

## Extending the AssetTable

Finally, we need to add links to our `AssetTable`. This will enable the user to click in a serial number to open the Asset tab:

```php
$l = new Link($asset->serial_no, Url::fromPath('training/asset/', ['serial' => $asset->serial_no]));

$r = Table::row([
    Html::tag('strong')->add($l->setBaseTarget('_next')),
    $asset->manufacturer,
    $asset->type,
    $asset->user->name ?? '-'
]);
```

# CSRF

The IPL also provides a `CsrfCounterMeasure` trait to simply mitigating cross-site request forgery.

This trait can be added to a form to add a hidden CSRFToken.

```php
use Icinga\Web\Session;
use ipl\Web\Common\CsrfCounterMeasure;

class MyForm extends Form
{
use CsrfCounterMeasure;

    protected function assemble()
    {
      $this->add($this->createCsrfCounterMeasure(Session::getSession()->getId()));
...
```
