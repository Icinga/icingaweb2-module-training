# Using JavaScript in Icinga Web Modules

Icinga Web Modules consist mainly of PHP code, however, in some cases JavaScript is required for more dynamic behavior.

This section will show you how to work with JavaScript in Icinga Web Modules.

## Events

JavaScript in Icinga Web Modules is mostly used to run code when events occur, e.g. a button is clicked or a certain element is rendered.

To work with events in Icinga Web, it is recommended to understand the concept of "event bubbling", since the framework relies on this type of event propagation. In event bubbling, an event triggered on a child element propagates upwards through its ancestors in the DOM.

## Directory Structure

All JavaScript code is placed in the `public/js/` directory.

In the directory you can create a `module.js` file that is then automatically loaded when your module is enabled.

```
.
└── training                Basic directory of the module
    ├── configuration.php
    └── public
        ├── js              JavaScript for the module
            └── module.js
```

If you need to create more files in the `public/js/` directory, you need to register them in the `configuration.php`.
To register a JavaScript file:

```php
// To register the file "public/js/example.js"
$this->provideJsFile('example.js');
```

Icinga Web will add this code to its `js/icinga.min.js`. The unminified version of this can be found at `js/icinga.dev.js`.

This directory is also where you would place third-party JavaScript. A good practice is to use a `vendor` directory within `public/js` for third-party code.

In Icinga Web, you can use two kinds of classes to provide JavaScript:

- Behaviors
- Modules

## Behaviors

Behaviors can be used as "global" components registered with the core Icinga object.
The code they run does not have to be tied to any particular module.

```js
// The semicolon is just a safe-guard
;(function(Icinga) {

    "use strict";

    class ExampleBehavior extends Icinga.EventListener {

       constructor(icinga) {
            super(icinga);

            // Register a method for events on specific elements.
            // In this case: a click event on elements with the 'click-me' class
            // will cause the onButtonClick method to be called
            this.on('click', '.click-me', this.onButtonClick, this);
       }

       onButtonClick(event) {
            // The 'event' is an standard Event with all it's attributes and methods
            event.stopPropagation();
            event.preventDefault();

            console.log("Button was clicked");
       }
    }

    // Register the new Behavior in the central Icinga object
    Icinga.Behaviors.ExampleBehavior = ExampleBehavior;

}(Icinga));
```

Note that the `this.on()` method uses event bubbling.
Meaning, the registered method is triggered when an event from a child element (of the registered element) propagates upwards through its ancestors.
This allows you to register methods for elements that might not exist yet in the DOM.

The use of `"use strict";` is recommended.

## Modules

Modules will only be loaded on a route of the specific Icinga Web Module.

Note, in this example we pass jQuery (`$`), which is bundled with Icinga Web, to our class.

```js
;(function (Icinga, $) {

    "use strict";

    class ExampleModule {
        constructor(module) {
            this.icinga = module.icinga;

            this.on('click', '.click-me', this.onButtonClick, this);
        }

        onButtonClick(event) {
            event.stopPropagation();
            event.preventDefault();

            // When we pass jQuery, we can use it in our module
            $("#example").fadeOut();
        }

        // All classes should implement a `destroy()` to clean up, this is best practice.
        destroy() {
            // Unbind the event handler
            this.off('click');
        }
    }

    Icinga.availableModules.examplemodule = ExampleModule;

})(Icinga, jQuery);
```

JavaScript code can use jQuery provided by Icinga Web, but you should use native alternatives if available.

## Advanced use-cases

The following contains more advanced use-cases that you won't need in most cases.

You can use the `define` function to load code from outside your module:

```js
;(function (Icinga, $) {
    define(['icinga/icinga-php-library/vendor/Sortable'], Sortable => {
    ...
    });
})(Icinga, jQuery);
```
