# Permissions

Each permission in Icinga Web is denoted by a namespaced key, which is used to group permissions.
The wildcard `*` can be used to grant all permissions in a certain namespace. Examples:

* `training/assets`
* `training/assets/users`
* `training/*`

In order to create a permission for an Icinga Web module, we register each permission in its `configuration.php` like so:

```php
<?php

$this->providePermission(
    'training/assets',
    $this->translate('Allow to view and configure assets')
);

$this->providePermission(
    'training/assets/users',
    $this->translate('Allow to view and configure users of assets')
);
```

We can now use these permissions in our Controllers by using the `assertPermission()` method. For example in the `init()` method which is called by the constructor. This would require a user to have the given permission for the entire Controller.

```php
public function init()
{
    // Checking permissions should be the first thing to do
    $this->assertPermission('training/assets');
}
```
Hint: `init()` isn't a PHP function, it is provided by the Zend Framework to help initialize without having to rewrite the constructor yourself.

Otherwise we can also use permissions in certain actions of the Controller to have more granular access.

```php
public function listAction()
{
    $this->assertPermission('training/assets-ro');
```

Hint: all configuration options that affect modules are covered by the permission `config/modules`. This can be used when your module provides configuration.

Further information on permissions can be found here:

* [Icinga Web Documentation](https://icinga.com/docs/icinga-web/latest/doc/06-Security/#permissions)
