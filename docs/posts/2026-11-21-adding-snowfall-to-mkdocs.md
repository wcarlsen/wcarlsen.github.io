---
date: 2026-11-21
tags:
  - mkdocs
  - javascript
---

# Adding snowfall to Mkdocs - because why not

It is November, less sun, cold weather and freezing temperatures are upon us (at least in Denmark). We should all be adding snowfall to our websites and blogs, to brighten up the mood of others and hopefully induce a smile or two. This will be a very short and simple guide of one of doing it in Mkdocs.

### How to add snowfall to Mkdocs

Adding snowfall is pretty straight forward. Pick your favorite snowfall Javascript package and add it under the `extra_javascript` section in your Mkdocs configuration file `mkdocs.yaml`. I have chooosen [magic-snowflakes](https://www.npmjs.com/package/magic-snowflakes), but you do you. Magic-snowflake can be setup in two ways, one without settings and one with. I will show you both in case beatiful customization is needed.

![mkdocs-snowfall](../assets/images/mkdocs-snowfall.png)


#### Without settings

```yaml
# Without settings
extra_javascript:
  - https://unpkg.com/magic-snowflakes/dist/snowflakes.auto.min.js
```

#### With custom settings

```yaml
# With settings
extra_javascript:
  - https://unpkg.com/magic-snowflakes/dist/snowflakes.min.js
  - docs/javascripts/snowfall.js
```

We of course need to add the following file `docs/javascripts/snowfall.js`.

```javascript
new Snowflakes({
  // add your settings here
});
```

It is recommended to use the color blue for the snowflakes, since it works great in both light and dark mode.
