# Digging Deeper – The Icinga Web Builtin Libraries

Icinga Web itself already provides some useful libraries which can be used inside of your module.
These libraries can be found inside of the library directory of [Icinga Web](https://github.com/Icinga/icingaweb2/tree/main/library/Icinga/Web)

The following will list some of the available functionalities you can implement to improve your module.

## Logger

We can use the `Icinga\Application\Logger` class to provide logging capabilities to our module.

A Logger has multiple static functions corresponding to common log levels:

```php
<?php
use Icinga\Application\Logger;

public function exampleMethod()
{
    Logger::error('This is terrible!');
    Logger::warning('Not great, not terrible.');
    Logger::info('This just happened');
    Logger::debug('For debug eyes only');
}
```

The `Logger` class uses its `$writer` to output the messages. Icinga Web provides several predefined `LogWriter` classes in `Icinga\Application\Logger\Writer`.

## FileCache

To implement a cache logic into your module, you can use the [FileCache](https://github.com/Icinga/icingaweb2/blob/main/library/Icinga/Web/FileCache.php) class.

`FileCache` can be used to write and read a cache at file level. Files will be saved into the `sys_get_temp_dir()`.
The `FileCache` class has no cache invalidation implemented. If this is necessary for your use case, you will have to implement this by yourself.

```php
use Icinga\Web\FileCache;
use Icinga\Application\Logger;

...

/**
 * storeCache stores the provided data in a FileCache instance named 'training'
 * @param string $storageName Name of the storage to store into
 * @param mixed $data
 * @return void
*/
protected function storeCache($storageName, $data): void
{
    try {
        $cache = FileCache::instance('training');
        $cache->store($storageName, $data);
    } catch (IcingaException $e) {
        Logger::error('Could not store %s to training cache: %s', $storageName, $e->getMessage());
    }
}

/**
 * loadCache loads the OnCall Contact data from a FileCache
 * @param string $storageName Name of the storage to load
 * @return string
*/
protected function loadCache($storageName): string
{
    $cachedData = null;

    try {
        $cache = FileCache::instance('training');
        $cachedData = $cache->get($storageName);
    } catch (IcingaException $e) {
        Logger::error('Could not load %s from training cache: %s', $storageName, $e->getMessage());
    }

    return $cachedData;
}
```
