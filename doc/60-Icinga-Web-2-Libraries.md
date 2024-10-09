# Digging Deeper – The Icinga Web 2 Builtin Libraries

Icinga Web 2 itself already provides some useful libraries which can be used inside of your module.
These libraries can be found inside of the library director of [Icinga Web 2](https://github.com/Icinga/icingaweb2/tree/main/library/Icinga/Web)

## Useful Libraries

The following will list some of the available functionalities you can implement to improve you module.

### FileCache

To implement a cache logic into your module, you can use [FileCache](https://github.com/Icinga/icingaweb2/blob/main/library/Icinga/Web/FileCache.php).  
`FileCache` can be used to write and read a cache at file level. Files will be saved into the `sys_get_temp_dir()`.

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
