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

# Restrictions

Once a user has permissions on a data set, we can use restrictions to reduce this data to a subset by specifying a filter expression.
By default, when no restrictions are defined, a user will be able to see the entire data set.

These expressions can be a comma-separated list of terms, or a full-blown filter.

For example, in the previous Asset database example, we use a permission to allow a user to see the assets
and use a restriction to allow the user to see only certain assets.

Similar to permissions, we need to register each restriction in the module's `configuration.php` like so:

```php
$this->provideRestriction(
    'training/filter/assets',
    $this->translate('Restrict access to the assets that match the filter')
);
```

We can now add a new role in Icinga Web's Access Control that uses this restriction.
For example, if we want to restrict by manufacturer we would set the restriction: `manufacturer=dell`.

Now we need to access this restriction in our controllers to modify what the user can see.

Since restrictions can be complex expressions the IPL provides the tools to parse these patterns.

A good place for this is a trait that we can re-use across our module:

```php
// vim library/Training/Auth.php

<?php

namespace Icinga\Module\Training;

use Icinga\Authentication\Auth as IcingaAuth;
use Icinga\User;
use ipl\Orm\Query;
use ipl\Stdlib\Filter;
use ipl\Web\Filter\QueryString;

trait Auth
{
    public function getAuth(): IcingaAuth
    {
        return IcingaAuth::getInstance();
    }

    // Apply the module's restrictions to a query the current users is running
    public function applyRestrictions($query)
    {
        $user = $this->getAuth()->getUser();

        // If the user is unrestricted no restrictions apply
        if ($user->isUnrestricted()) {
            return;
        }

        // The final filter that is applied to the query.
        // Any means any filter has to match
        $queryFilter = Filter::any();

        // For each of the user's roles add the given restrictions
        foreach ($user->getRoles() as $role) {

            // All means ALL filters have to match
            $roleFilter = Filter::all();

            // Load the restrictions for the user's role and parse them into a filter
            $restriction = $role->getRestrictions('training/filter/assets');

            if ($restriction) {
                // Parse the given restriction and return a Filter\Rule
                $queryRestriction = QueryString::fromString($queryString)->parse();
                // Add the new Rule to the role filter
                $roleFilter->add($queryRestriction);
            }

            // Add the filter to the overall queryfilter
            if (! $roleFilter->isEmpty()) {
                $queryFilter->add($roleFilter);
            }
        }

        $query->filter($queryFilter);
    }
}
```

In essence, what we see here is the restriction as a string being parsed into an `ipl-stdlib` Filter, which we then use to modify the SQL statement that will be executed.

* `applyRestrictions($query)` takes the existing SQL statement which we want to execute
* It loads all relevant restrictions from the user's roles
* Each restriction is parsed into a `Filter` and added to an overall `Filter`
* The overall `Filter` modifies the SQL statement accordingly

Hint: the QueryString Parser also emits signals via the `ipl-stdlib Events` trait. This means, that we can hook into the process and modify things, similar to Forms.

With these methods in place we can adjust our controllers to apply the restriction:

```php
// vim application/controllers/AssetsController.php

use Icinga\Module\Training\Auth;

class AssetsController extends CompatController
{
    use Auth;

    public function indexAction()
    {
        // After we created the query and applied search filters
        $this->applyRestrictions($query);
```

Filter expressions can be quite complex. Any filter expression that is allowed in the filtered view, is also an allowed filter expression. This means, that it is possible to define negations, wildcards, and even nested filter expressions containing AND and OR-Clauses.

Further information on restrictions can be found here:

* [Icinga Web Documentation](https://icinga.com/docs/icinga-web/latest/doc/06-Security/#restrictions)
