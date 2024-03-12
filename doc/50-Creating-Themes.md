# Creating Icinga Web Themes

Besides functionality and PHP code Icinga Web modules can also include custom themes.
Themes change allow you to customize the appearance of the web interface.

As already seen in the Module section, Icinga Web uses the CSS preprocessor Less for styling HTML.
Here are commonly used features of Less in Icinga Web themes.

## Less Features

With the `@`-sign we can define variables in Less.
This makes it simple set values at a central place and reuse them:

```
@pale-green: #98FB98;

#header {
  color: @pale-green;
}
```

Less includes several functions. Very commonly used are color operations (fade, darken, lighten, etc.):

```

#footer {
  color:  desaturate(@pale-green, 10%);
}
```

Less mixins are a way of including properties from one CSS ruleset into another:

```
.bordered {
  border-top: dotted 1px black;
  border-bottom: solid 2px black;
}

#menu a {
  .bordered();
}
```

A similar Less feature is a detached ruleset, which is a group of CSS properties, nested rulesets, or anything else stored in a variable:

```
@detached-ruleset: {
  background: red;
};

.top {
  @detached-ruleset();
}
```

Another commonly used feature is referencing a parent with the `&`-sign:

```
a {
  color: blue;

  /* instead of a:hover */
  &:hover {
    color: green;
  }
}
```

# Custom Themes

To create an Icinga web theme we need to create a stylesheet in `public/css/themes/`.

    .
    └── training
        ├── application
        ├── module.info
        ├── public
            └── css
                └── themes
                    └── my-theme.less


Once we create a stylesheet within this directory and the module containing the stylesheet is enabled in Icinga Web,
we can select the theme in our user's settings or the application's configuration.

```bash
cd /usr/local/icingaweb2-modules/training

mkdir -p public/css/themes/

vim public/css/themes/my-theme.less

/* My custom theme */
```

The name of the theme is a combination of the module's name and the stylesheet's filename: "training/my-theme".
If we create another file `my-other-theme.less` a second entry "training/my-other-theme" would appear.

Now that our stylesheet is at the right place let's use is to customize the web interface.
A simple change could be replacing the main interface colors:

```
/* The main interface colors */
@my-color: #ff847c;
@my-color-dark: #e84a5f;

/* Override Icinga Web's colors */
@icinga-blue: @my-color;
@icinga-blue-dark: @my-color-dark;
```

Hint: you can find these base variables in Icinga Web's `public/css` directory: `icingaweb2/public/css/icinga/base.less`.

By using the selectors of the UI elements we can now make further changes.
For example if we want to override the Icinga logo in the upper left corner.

First, we download a replacement image:

```
cd /usr/local/icingaweb2-modules/training

mkdir -p public/img

wget https://upload.wikimedia.org/wikipedia/commons/4/4f/SVG_Logo.svg
```

Now we update the `#header-logo`:

```
vim public/css/themes/my-theme.less

#header-logo {
    /* Loading files from training/public/img/ */
    background-image: url('../img/training/SVG_Logo.svg');
}

#header-logo-container {
    /* Adjusting the padding for a larger logo */
    padding: 0.33em;
}

#icinga-logo {
    /* Replacing the logo for the login page */
    background-image: url('../img/training/SVG_Logo.svg');
}
```

Hint: it is currently not possible to use the Less `@import` rule.

# Dark and Light Mode

Icinga Web themes can have light and dark modes.
In light mode the background is a light color and the text is dark.
On the contrary, dark mode flips this, with a dark background with light text.

Hint: since Icinga Web version 2.10 dark mode is the default.

If we want to add a light mode to our previously created theme, we need to create a detached rulesets named `light-mode`.

Within this detached rulesets we set everything that will be active when using the light mode.

```
vim public/css/themes/my-theme.less

@light-mode: {
    :root {
        --my-color: #fdb44b;
        --my-color-dark: #ff6f3c;
    }
};
```

The colors here are defined as CSS Custom properties, which start with two dashes `--`.
They are within the root selector `:root` to be global variables.
