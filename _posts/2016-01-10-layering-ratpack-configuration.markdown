---
layout: post
title: Layering Ratpack Configuration
date: 2016-01-10 08:07
comments: true
categories: ratpack
---

Over the last few weeks I have upgraded my pet project [CellarHQRatpack](https://github.com/CellarHQ/cellarhq.com) from the ancient Ratpack 0.9.15 to the current 1.1.1, and also moved it from being hosted on AWS Elastic Beanstalk to Heroku. In the process I redid the configuration more than 1 time. The [documentation](https://ratpack.io/manual/current/config.html#quick_start) while accurate, lacks any concrete examples. 

## Loading configuration in Ratpack

Ratpack can be configured in several different ways, including properties files, yaml, system properties and environment variables. Here's how I configure CellarHQ:

```groovy
ratpack {
  List<String> programArgs = HerokuUtils.extractDbProperties
    .apply(System.getenv("DATABASE_URL"))

  serverConfig {
    config -> config
      .baseDir(BaseDir.find())
      .props("app.properties")
      .yaml("db.yaml")
      .env()
      .sysProps()
      .args(programArgs.stream().toArray() as String[])
      .require("/cellarhq", CellarHQConfig)
      .require("/db", HikariConfig)
      .require("/metrics", DropwizardMetricsConfig)
      .require("/cookie", ClientSideSessionConfig)
  }

  bindings {
    module CommonModule
    module HikariModule
    module AuthenticationModule
    module CommonModule
    module ApiModule
    module WebappModule
    module HandlebarsModule
    module SessionModule
    module ClientSideSessionModule
    module DropwizardMetricsModule

    bindInstance Service, new Service() {
      @Override
      void onStart(StartEvent event) throws Exception {
        RxRatpack.initialize()
      }
    }

    bind ServerErrorHandler, ServerErrorHandlerImpl
    bind ClientErrorHandler, ClientErrorHandlerImpl
    bind DatabaseHealthcheck
  }
```

All configuration is added through the ```ServerConfig``` an requiring specific stanzas of configuration including cellarhq, db etc. An instance of each config object is added to the registry. This lets the ```bindings``` block stay very simple. Let's examine the configuration line by line:

```
List<String> programArgs = HerokuUtils.extractDbProperties
    .apply(System.getenv("DATABASE_URL"))
```

Heroku provides an environment variable which has all the fields for the JDBC connection which needs to be parsed and added to the Ratpack configuration manually. This is a helper utility I gratuitously stole from [Modern Java Web Development](https://github.com/danhyun/modern-java-web). 

```
  serverConfig {
    config -> config
      .baseDir(BaseDir.find())
      .props("app.properties")
      .yaml("db.yaml")
```

This will load two configuration files, one is a properties file and one is a yaml file, from the ratpack `BaseDir`. You'll want to define this by including a `.ratpack` file somewhere in your source tree. Mine is in `src/ratpack`. 

```
.args(programArgs.stream().toArray() as String[])
.sysProps()
.env()      
```

Now the herku specific configuration, system properties, environment variables are layered on top of the configuration files, in the order specified.  System properties override configuration from app.properties and environment variables override those.

```      
.require("/cellarhq", CellarHQConfig)
.require("/db", HikariConfig)
.require("/metrics", DropwizardMetricsConfig)
.require("/cookie", ClientSideSessionConfig)
```

Finally, specific configuration objects are built using data-binding from the specified properties. An instance of each of these classes is added to the registry and available just like any other object added to the registry.

## Setting the configuration

Now let's look at the configuration itself. In `app.properties` and `db.yaml` sensible defaults are configured for every configuration item that isn't secret like AWS or Twitter API keys. Those items are always configured at runtime and stored some place not in source control. 

```
liquibase.changelog=migations.xml
liquibase.onerror.fail=true

metrics.jvmMetrics=true
metrics.jmx.enabled=true
metrics.csv.enabled=false
metrics.webSocket.reporterInterval=PT30S
metrics.webSocket.excludeFilter=.*(js|css|ico|woff|admin|login|pac4j).*
metrics.requestMetricGroups.update=update.*
metrics.requestMetricGroups.delete=delete.*

cookie.sessionCookieName = cellarhq_session
cookie.secretToken = secretTokenIsOverridenInProd

cellarhq.googleAnalyticsTrackingCode=UA-27709782-2
cellarhq.hostname=localhost:5050
cellarhq.s3StorageBucket=storage-local.cellarhq.com
cellarhq.environment=development
```

```yaml
db:
  dataSourceClassName: org.postgresql.ds.PGSimpleDataSource
  username: cellarhq
  password: cellarhq
  dataSourceProperties:
    databaseName: cellarhq
    serverName: localhost
    portNumber: 15432
```

## Overriding with system properties or env vars

The defaults above work great for running locally, but I do override some of them for tests. I use the gradle build to set environment variables or system properties. Here's how I configure functional tests:

```groovy
task functionalTest(type: Test) {
  testClassesDir = sourceSets.functional.output.classesDir
  classpath = sourceSets.functional.runtimeClasspath

  systemProperty 'liquibase.changelog', rootProject.file('model/migrations/migrations.xml').canonicalPath
  systemProperty 'liquibase.schema.default', 'public'
  systemProperty 'liquibase.onerror.fail', true
  maxHeapSize '768m'

  if (System.getenv('SNAP_CI')) {
    environment 'RATPACK_DB__DATA_SOURCE_PROPERTIES__SERVER_NAME', System.getenv('SNAP_DB_PG_HOST')
    environment 'RATPACK_DB__DATA_SOURCE_PROPERTIES__PORT_NUMBER', System.getenv('SNAP_DB_PG_PORT')
    environment 'RATPACK_DB__DATA_SOURCE_PROPERTIES__DATABASE_NAME', 'app_test'
    environment 'RATPACK_DB__USER', System.getenv('SNAP_DB_PG_USER')
    environment 'RATPACK_DB__PASSWORD', System.getenv('SNAP_DB_PG_PASSWORD')
    environment 'RATPACK_CELLARHQ__AWS_ACCESS_KEY', System.getenv('AWS_ACCESS_KEY') ?: 'BAD_KEY'
    environment 'RATPACK_CELLARHQ__AWS_SECRET_KEY', System.getenv('AWS_SECRET_KEY') ?: 'BAD_KEY'
    environment 'RATPACK_CELLARHQ__TWITER_API_KEY', System.getenv('TWITTER_API_TOKEN') ?: 'BAD_KEY'
    environment 'RATPACK_CELLARHQ__TWITTER_API_SECRET', System.getenv('TWITTER_API_SECRET') ?: 'BAD_KEY'

    testLogging.showStandardStreams = true
  } else {
    environment 'RATPACK_DB__DATA_SOURCE_PROPERTIES__DATABASE_NAME', 'cellarhq_testing'
    if (project.hasProperty('awsAccessKey')) {
      environment 'RATPACK_CELLARHQ__AWS_ACCESS_KEY', project.awsAccessKey
      environment 'RATPACK_CELLARHQ__AWS_SECRET_KEY', project.awsSecretKey
      environment 'RATPACK_CELLARHQ__TWITER_API_KEY', project.twitterApiKey
      environment 'RATPACK_CELLARHQ__TWITTER_API_SECRET', project.twitterApiSecret
    }
  }
}
```

The build detects if it is running in a CI environment and maps configuration appropriately. Otherwise it sets a new database name and loads secrets from the gradle properties. I keep secrets in `~/.gradle/gradle.properties` so they will never be added to source control accidentally.

There are some important things to notice here:

* Environment variables start with `RATPACK_`, system properties with `ratpack.`
* For env vars, TWO underscores are used to separate objects like CELLARHQ__
* For env vars, ONE underscore is used to separate words that are built into camel cased field names, like AWS_ACCESS_KEY.
* For system properties, the `.` is used for both object and field separators.

So, `RATPACK_DB__DATA_SOURCE_PROPERTIES__DATABASE_NAME` and `ratpack.db.dataSourceProperties.databaseName` are equivalent. Using system properties or environment variables is mostly a matter of preference.

## What about lists?

I don't have any properties which data-bind to lists, but this is possible in ratpack. Let's say I had multiple S3 storage buckets configured, that could be configured in a properties file like this:

```
cellarhq.s3StorageBuckets[0]=storage-local.cellarhq.com
cellarhq.s3StorageBuckets[1]=storage-local.cellarhq.com
cellarhq.s3StorageBuckets[2]=storage-local.cellarhq.com
```

It could be done similarly with system properties. However, this DOES NOT WORK with environment variables. You cannot set items in a list using environment variable configuration.

## Conclusion

Ratpack configuration is simple and elegant, and it is easy to layer environment specific configuration on top of defaults, I just thought there needed to be a few real life examples out there. 



