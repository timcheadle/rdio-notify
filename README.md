# rdio-notify

Simple app to see if artists in your [Rdio](http://rdio.com) collection
have new releases. Requires an Rdio subscription and a developer API
key.

It's a basic Sinatra app, so run as follows:
```
$ git clone git@github.com:timcheadle/rdio-notify.git
$ cd rdio-notify
$ ./rdio-notify.rb
```
Now go to [http://localhost:4567](), log in and enjoy!

### Rdio API Keys

You'll need to put your API keys in `rdio-credentials.rb`. Here's the
file format:
```
RDIO_CONSUMER_KEY    = ''
RDIO_CONSUMER_SECRET = ''
```

If you don't currently have an API key, go apply for one at the [Rdio
Developer Site](http://developer.rdio.com/).
