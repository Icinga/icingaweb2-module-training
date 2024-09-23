# IPL and HTML

Both `ipl-html` and `ipl-web` are essential libraries when working with Icinga Web modules.
This section will give an overview of some of their features.

## ipl-html

`ipl-html` provides an HTML abstraction layer for the IPL. It lets you write HTML in an object oriented way

### ipl\Html\Html

The most basic use is the `Html::tag` static method:

```php
use ipl\Html\Html;

Html::tag('h1', 'Hello there!');

Html::tag('h1', ['Hello', 'out' ,'there!']);
```

You can pass some attributes to these tags, with or without content:

```php
Html::tag('p', ['class' => 'error'], 'Something failed');

Html::tag('ul', ['role' => 'mylist']);
```

Any object that implements the `ipl\Html\ValidHtml` interface can be passed as content:

```php
Html::tag('ul', ['role' => 'mylist'], Html::tag('li', 'A point'));

Html::sprintf('Hello %s', Html::strong('world');
```

### ipl\Html\Text

`ipl\Html\Text` is a primitive element that renders text to HTML while automatically escaping its content.

```php
$text = Text::create('This is true: 2 > 1');

$header = new HtmlElement('h2', null, new Text(t('My Headline')));
```

### ipl\Html\BaseHtmlElement

The abstract class `BaseHtmlElement` can be used to create custom HTML elements in your module.
To see how this works, have a look at the `ipl\Html\Table` class.

## ipl-web

`ipl-web` provides common web components.

### ipl\Web\Widget\Link

The `ipl\Web\Widget\Link` class provides a simple way to create a HTML link.

```php
use ipl\Web\Widget\Link;
$l = new Link('content', 'url', ['class' => mylink']);

// Result: <a class="mylink" href="/url">content</a>
```

### ipl\Web\Widget\Icon

The `ipl\Web\Widget\Icon` class can be used to create icons.

```php
use ipl\Web\Widget\Icon;
$i = new Icon('user');

// Result: <i class="icon fa-user fa"><div></div></i>
```

The IPL uses the free [Font Awesome](https://fontawesome.com) icons.

### ipl\Web\Widget\StateBall

When working with Icinga's monitoring states you can use the `ipl\Web\Widget\StateBall` to display a status:

```php
use ipl\Web\Widget\StateBall;
$s = new StateBall('warning', StateBall::SIZE_LARGE);

// Result: <span class="state-ball state-warning ball-size-xl"></span>
```

# Content-Security-Policy

This section assumes you are familiar with the basic concepts of CSP.

The [Content-Security-Policy](https://content-security-policy.com/) header allows you to restrict which resources (such as JavaScript, CSS, Images, etc.) can be loaded, and the URLs that they can be loaded from.

By default Content-Security-Policy header prevents execution of any inline scripts and inline styles.

If you require inline styles or scripts in your module, you can do this:

```php
use ipl\Web\Compat\StyleWithNonce;
use ipl\Html\Html;

// First, we create an HTML Element that we want to give an inline style.
// This is just an example:
$i = Html::tag('i', null, '(active)');

// Then, we prepare a new Style object with a nonce value:
$style = (new StyleWithNonce())
    ->setModule('training');

// Now, we can add an inline style:
$style->addFor($i, ['color' => 'white', 'background' => 'hotpink']);

// Finally we add the HTML element and its style to our content:
$b = Html::tag('p', ['class' => 'user'], 'J. Doe');
$b->add([$i, $style]);
```

**Hint:** This requires Icinga Web 2.12 and ipl-web 0.13.0.
