# Convorse

## Getting Started

Convorse is written with [Revel](http://revel.github.io), A high-productivity web framework for the [Go language](http://www.golang.org/).

Place this gocode directory in your `$GOPATH/src/` and rename it to convorse.

What the file structure should be like: `$GOPATH/src/convorse/app/views/...`

### Start the web server:

    revel run convorse

   Run with <tt>--help</tt> for options.

### Go to http://localhost:9000/

And you should see the convorse desktop login screen

### Description of Contents

The default directory structure of a generated Revel application:

    myapp               App root
      app               App sources
        controllers     App controllers
          init.go       Interceptor registration
        routes          Reverse routes (generated code)
        views           Templates
      tests             Test suites
      conf              Configuration files
        app.conf        Main configuration file
        routes          Routes definition
      messages          Message files
      public            Public assets
        css             CSS files
        js              Javascript files
        images          Image files
      database          Database wrapper
      serialize         ComputerCraft serializer

app

    The app directory contains the source code and templates for your application.

conf

    The conf directory contains the application’s configuration files. There are two main configuration files:

    * app.conf, the main configuration file for the application, which contains standard configuration parameters
    * routes, the routes definition file.
