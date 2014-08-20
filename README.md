# livenico [![Build Status](https://secure.travis-ci.org/hdemon/livenico.js.png?branch=master)](http://travis-ci.org/hdemon/livenico.js)

Utilities for niconico live.

## Getting Started
Install the module with: `npm install livenico`

```javascript
Nico = require './lib/livenico'

n = new Nico({
  mail: "hoge@example.org"
  password: "123456"
})

(n.getMovieComment "sm9").then (data) -> console.log data.toString()
(n.getLiveMovieComment "lv189823440").then (data) => console.log data.toString()
```

## Documentation
_(Coming soon)_

## Examples
_(Coming soon)_

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

## Release History
_(Nothing yet)_

## License
Copyright (c) 2014 Masami Yonehara
Licensed under the MIT license.
