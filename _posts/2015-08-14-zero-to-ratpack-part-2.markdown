---
layout: page
title: Zero to Ratpack - Part 2
date: 2015-08-14 14:34
comments: true
categories: ratpack
---

# Some Notes
I want to point out the excellent reference project for Ratpack called [example-books](https://github.com/ratpack/example-books). This is what I reference when I need to figure out how to do something or what has changed in a Ratpack release. It is updated for every Ratpack release. 

Lastly, I've been considering switching the examples in this blog series from Groovy to Java. One advantage of Ratpack is the Groovy DSL and how simple it is to create a quick application with it, but I do think it hides what is really happening in Ratpack a bit. I've decided to stay with Groovy, but to post the equivalent Java once I'm done with the main series.

You can find all the code for this post on [github](https://github.com/kyleboon/ratpack-reverse-proxy) with the tag 'config-and-testing'

# Configuration

Previously, the Reverse Proxy was hard coded to proxy all requests to [cellarhq](https://www.cellarhq.com). That isn't very useful, it would be better to based on an external config file. Ratpack's [configuration](https://ratpack.io/manual/current/config.html#config) is excellent. It supports yaml, properties files, system properties, and environment variables to name a few, and more formats can be supported easily. 

```groovy
serverConfig { d -> d
  .props(Resources.asByteSource(Resources.getResource('application.properties')))
  .env()
  .sysProps()
  .require('/proxyConfig', ProxyConfig)
}
```

Loading configuration from a file and then layering on environment variables and system properties happens in the ```ratpack``` block of ```ratpack.groovy```. The ```ServerConfig``` is available globally to anything that has access to the registry. The configuration specific to the reverse proxy is stored in a plain old groovy object, and is also added to the registry. 

```groovy
package reverseproxy.config

class ProxyConfig {
	String forwardToHost = 'InvalidHost'
	Integer forwardToPort = 80
	String forwardToScheme = 'http'
}
```

Finally, the ```ProxyConfig``` instance can be accessed from the registry and then used in handlers. 

```groovy
all { HttpClient httpClient, ProxyConfig proxyConfig ->
  URI requestURI = new URI(request.rawUri)
  URI proxyUri = new URI(
          proxyConfig.forwardToScheme,
          requestURI.userInfo,
          proxyConfig.forwardToHost,
          proxyConfig.forwardToPort,
          requestURI.path,
          requestURI.query,
          requestURI.fragment)

  httpClient.requestStream(proxyUri) { RequestSpec spec ->
    spec.headers.copy(request.headers)
  }.then { StreamedResponse responseStream ->
    responseStream.forwardTo(response)
  }
}
```

# Testing

So far the reverse proxy is very basic and doesn't do much. Before additionally functionality is layered on, it is important to have a functional test to ensure everything keeps working. Testing is an important part of Ratpack and I [previously wrote]{% post_url 2016-06-30-validating-an-http-post-with-ratpack %} about how Ratpack can actually improve the testing of Grails and other frameworks. 

A functional test of the reverse proxy requires a proxy target and it is best to avoid external dependencies in tests. Ratpack provides a fantastic feature to overcome this using an ```EmbeddedApp``` in the test itself.  

```groovy
class ReverseProxyBasicTest extends Specification {
  @Shared
  ApplicationUnderTest aut = new GroovyRatpackMainApplicationUnderTest()

  TestHttpClient client = aut.httpClient

  @Shared
  EmbeddedApp proxiedHost = GroovyEmbeddedApp.of {
    handlers {
      all {
        render "rendered ${request.rawUri}"
      }
    }
  }

  def setupSpec() {
    System.setProperty('ratpack.proxyConfig.forwardToHost', proxiedHost.address.host)
    System.setProperty('ratpack.proxyConfig.forwardToPort', Integer.toString(proxiedHost.address.port))
    System.setProperty('ratpack.proxyConfig.forwardToScheme', proxiedHost.address.scheme)
  }

  def "get request to ratpack is proxied to the embedded app"() {
    expect:
    client.getText(url) == "rendered /${url}"

    where:
    url << ["", "api", "about"]
  }
}
```

This tests starts the Reverse Proxy application, that's the application under test, creates a test http client to call the reverse proxy and then creates an embedded app that is *separate* from the application under test in order to proxy requests to that embedded application. The embedded app is just rendering text back to the proxy. The ```setupSpec()``` is setting several system properties. Those system properties are being used by the ```ConfigData``` instance in the Ratpack application to set configuration for the embedded application. There's no need for a test configuration file because of this. Each test can easily specify the configuration it needs and no more.

Finally the test makes an http request to the Reverse Proxy and verifies the result is as expected. This is a simple but powerful test and each new feature added to the reverse proxy will begin with a test.

# Adding a second handler

It would be nice to be able to view the configuration for the reverse proxy via a simple html page rendered by the application itself. It's an easy first feature to add, and demonstrates adding a path specific handler.

First though, a test.

```groovy
class ConfigPageTest extends GebReportingSpec {
  @Shared
  ApplicationUnderTest aut = new GroovyRatpackMainApplicationUnderTest()

  def setupSpec() {
    System.setProperty('ratpack.proxyConfig.forwardToHost', 'testhost')
    System.setProperty('ratpack.proxyConfig.forwardToPort', '123')
    System.setProperty('ratpack.proxyConfig.forwardToScheme', 'https')
  }

  def setup() {
    browser.baseUrl = aut.address.toString() + 'reverseProxyAdmin'
  }

  def "admin page displays config"() {
    when:
    to ConfigPage

    then:
    host == "Proxied Host: testhost"
    port == "Proxied Port: 123"
    scheme == "Proxied Scheme: https"
  }
}
```

This test uses [Geb](https://www.gebish.org/) to functionally test a page through firefox. Geb is beyond the scope of this article, but it is an easy (and default) way to test html generated by Ratpack. Here, we verify that there is a page that responds to ```/reverseProxyAdmin``` and has 3 ```<li>``` elements which include the configuration data.

The handler and template to generate this are simple. You will need to add the Handlebars module to the application. Modules are the method Ratpack uses to add functionality not included in Ratpack core. Most functionality is in a module, because Ratpack tries to be as unopinionated as possible. Simple add ```module HandlebarsModule``` to the ```bindings``` block of ```ratpack.groovy``` and add the build dependency ```compile ratpack.dependency('handlebars')``` to ```build.gradle```.

Create a ```handlebars``` directory inside of the ```ratpack``` source directory then create a ```reverseProxyAdmin.html.hbs``` file. Remove the spaces between the braces, I couldn't get octopress to render them correctly without it.

```html
<html>
  <head>
      <title>Reverse Proxy Config</title>
  </head>
  <body>
    <h1>Config Data</h1>
    <ul>
      <li>Proxied Host: { { config.forwardToHost } }</li>
      <li>Proxied Port: { { config.forwardToPort } }</li>
      <li>Proxied Scheme: { { config.forwardToScheme } }</li>
    </ul>
  </body>
</html>
```

Finally the new handler must be added to ```handlers``` block of ```ratpack.groovy```.

```groovy
get('reverseProxyAdmin') { ProxyConfig proxyConfig ->
    render handlebarsTemplate('reverseProxyAdmin.html', config: proxyConfig)
}
```

The handler itself is very simple. It just renders a handlebars template and passes a map containing the configuration to the template. Using ```get``` with a path instead of ```all``` means that this handler will be invoked only when there is an ```HTTP GET``` request to ```/reverseProxyAdmin```. Technically this means the application can't reverse proxy anything to that path, but I think we can live with that for now. Try adding this handler below the original handler and then start the application and navigate to the page.

It didn't work did it? That's because handlers are executed in order and only 1 handler may render a response. So the ```all``` handler intercepted the request and proxied it. Most likely you received a 404 from the proxied host. To fix this, just reverse the order of the handlers and try again. This is an important thing to remember when building Ratpack applications! It is quite different than MVC frameworks like grails or rails which have a routing definition which says which controller to call for which URLs. 

# Conclusion

We layered some additional functionality into the application and added tests. It's almost a real application now! In the next series we will start to move code out of the ```Ratpack.groovy``` file and see how a larger application can be structured. In doing so, we'll add a few new features to the application and explore logging and more handler composition with Ratpack.



