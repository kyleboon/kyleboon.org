---
layout: post
title: Dropwizard project template
date: 2013-07-05 19:45
comments: true
categories: dropwizard, lazybones, groovy 
---

At [bloomhealth](http://www.gobloomhealth.com/jobs/) we use
[dropwizard](http://dropwizard.codahale.com/) to build small, fast web
services. Recently I've been contributing to Peter Ledbrook's
[lazybones](https://github.com/pledbrook/lazybones) project templating
system and I finally made time to build a template for dropwizard. 

The template creates a default directory structure, an empty service
implementation and a gradle build. There are some custom gradle tasks
for running migrations and starting the service. It includes
dependencies for testing with spock as well.  You can see the
[template](https://github.com/kyleboon/lazybones-dropwizard-template) on
github.

You can install lazybones via gvm. If you're not using gvm, then you
should start.

```
gvm install lazybones
lazybones create dropwizard 0.1 ~/my-dropwizard-project
```

Lazybones will prompt you for some information to build the template
with.

```
Define value for 'group': org.kyleboon
Define value for 'version' [0.1]: 0.1
Define value for package structure: org.kyleboon.contact
Define value for the name of the service: Contact
```

After that it will display the README for the template and tell you the
project has been created.

```
Filtering file /Users/kboon/temp/gradle.properties
Filtering file
/Users/kboon/temp/src/main/groovy/packageName/ServiceNameService.groovy
Filtering file
/Users/kboon/temp/src/main/groovy/packageName/ServiceNameConfiguration.groovy
     [move] Moving 2 files to
/Users/kboon/temp/src/main/groovy/org/kyleboon/contact

# Introduction

You have created an dropwizard application using lazybones. The
application will start but it has no resources
configured for it yet. To find out where to go from here, visit the
[dropwizard documentation](dropwizard.codahale.com).

There is a working service, liquibase migrations, hibernate support and
a basic gradle build system including some
shortcuts to the commands for running migrations and starting the
service.

Enjoy!

<proj>
      +- src
          +- main
          |   +- groovy
          |   |     +- your.package.structure
          |   |           +- core
          |   |           +- db
          |   |           +- healthchecks
          |   |           +- resources
          |   |           +- core
          |   +- resources
          |
          +- test
              +- groovy
              |     +- // Spock tests in here!
              +- resources
                    +- fixtures

# Running The Application

To test the example application run the following commands.

* To run the tests run

`gradle test`

* To package the example run.

        gradle shadow

* To drop an existing h2 database run.

        gradle dropAll

* To setup the h2 database run.

        gradle migrate

* To run the server run.

        gradle run

Project created in /Users/kboon/temp!
```

And you're ready to go! At this point you can run the service using
```gradle run```. Gradle will build and test the application, create a
runnable jar with the shadow plugin and then start the service. When you
do, you will notice a warning from dropwizard because there are no
resources defined yet so there are no available routes for the service.
This is where you pick up...

The next version of the template will include gradle tasks to generate
swager documention and run gatling load tests.
