---
layout: page
title: Zero to Ratpack - Part 3
date: 2016-04-10 11:05
comments: true
categories: ratpack
published: true
---

It has been a while since I wrote another entry in this series but I was energized at Greach 2016 and I wanted to finish it.

The next step in the reverse proxy is to add additional features. Each new feature is implemented as an additional handler and added to the chain before the handler which will actually call the proxy target and stream the response.

There's a lot of code in this post. You can see the entire project on [github](https://github.com/kyleboon/ratpack-reverse-proxy). I'm not including the tests for the new handlers in this post because they are very similar to the functional test in [part 2]{% post_url 2015-08-14-zero-to-ratpack-part-2 %} and you can see them on github.

## Refactoring to Modules

The first step is to refactor the existing code into modules. Modules are the top level organizational unit for functionality in Ratpack. In this application there are two modules, an Administration module and a Proxy module. 

```groovy
package reverseproxy.admin

import com.google.inject.AbstractModule

class AdminModule extends AbstractModule {
	@Override
	protected void configure() {
		bind(ConfigHandler)
	}
}
```

The administration module doesn't have much to it. The ```ConfigHandler``` is bound to the guice registry and that's it.

```groovy
class ProxyModule extends AbstractModule {
	@Override
	protected void configure() {

	}

	static class Config {
		String forwardToHost = 'InvalidHost'
		Integer forwardToPort = 80
		String forwardToScheme = 'http'
		Boolean logRequests = false
		List<Pattern> filterOut = []

		String canaryHost = null
		Integer canaryPort = null
		String canaryScheme = null
		Integer canaryPercentage = null

		boolean isCanaryEnabled() {
			canaryHost && canaryPort && canaryScheme && canaryPercentage
		}
	}

	static ProxyHandler proxyHandler() {
		return new ProxyHandler()
	}

	static LoggingHandler loggingHandler() {
		return new LoggingHandler()
	}

	static CanaryRoutingHandler canaryHandler() {
		return new CanaryRoutingHandler()
	}

	static BlacklistHandler blacklistHandler() {
		return new BlacklistHandler()
	}
}
```

The proxy module is similar to the Admin module, but with new handlers for each feature that is being added to the reverse proxy. The config object also became an internal class of the module which is idiomatic Ratpack. The static methods to retrieve handler instances is also idiomatic Ratpack, when you don't need (or want) to use guice. You’ll notice it in many of the default Ratpack modules. The ratpack.groovy script needs updated to reflect the new modules.

```groovy
ratpack {
  serverConfig { d -> d
    .props(Resources.asByteSource(Resources.getResource('application.properties')))
    .env()
    .sysProps()
    .require('/proxyConfig', ProxyModule.Config)
  }

  bindings {
    module HandlebarsModule
    module ProxyModule
    module AdminModule
  }

  handlers {
    get('reverseProxyAdmin', ConfigHandler)

    all ProxyModule.loggingHandler()
    all ProxyModule.blacklistHandler()
    all ProxyModule.canaryHandler()
    all ProxyModule.proxyHandler()
  }
}
```

Each of the new handlers is added to the chain. 

## The handlers

The logging handler. This handler simply logs the request and then executes the ```next``` method to move down the chain. 

```groovy
@Slf4j
class LoggingHandler extends GroovyHandler {
	@Override
	protected void handle(GroovyContext context) {
		context.with {
			ProxyModule.Config config = context.get(ProxyModule.Config)

			if (config.logRequests) {
				Request request = context.request
				request.body.then { TypedData body ->
					Blocking.exec {
						String logMessage  = """path=${request.path}
                                            method=${request.method.name}
                                            params=${request.queryParams}
                                             body=${body.text}
                                         """.stripIndent()
						log.info(logMessage)
					}
				}

			}
			next()
		}
	}
}
```

The blacklist handler. This handler matches all the request uris against a regular expression and does not forward the request on to the proxy target.


```groovy
class BlacklistHandler extends GroovyHandler {
	@Override
	protected void handle(GroovyContext context) {
		context.with {
			ProxyModule.Config config = context.get(ProxyModule.Config)

			if (config.filterOut.any { it.matcher(context.request.path).matches() }) {
				context.render("Request path has been blacklisted")
			} else {
				next()
			}
		}
	}
}
```

The configuration is retrieved from the registry and then the request path matches any of the configured blacked out urls. If so, the handler calls ```context.render``` and does *not* call ```next```. That means the rest of the handlers in the chain won't be executed. Generally, handlers which render a response will not call ```next```. 

The last and most interesting new handler is the canary handler. This handler allows a percentage of requests to be proxied to a canary target instead of the normal target. 

```groovy
class CanaryRoutingHandler extends GroovyHandler {
	@Override
	protected void handle(GroovyContext context) {
		context.with {
			ProxyModule.Config config = context.get(ProxyModule.Config)
			URI requestURI = new URI(request.rawUri)
			URI proxyUri

			if (config.canaryEnabled) {
				Random random = ThreadLocalRandom.current()
				Long randomLong = random.nextLong()

				if (randomLong % 100 <= config.canaryPercentage) {
					proxyUri = new URI(
							config.canaryScheme,
							requestURI.userInfo,
							config.canaryHost,
							config.canaryPort,
							requestURI.path,
							requestURI.query,
							requestURI.fragment)
				}
			}

			if (!proxyUri) {
				proxyUri = new URI(
						config.forwardToScheme,
						requestURI.userInfo,
						config.forwardToHost,
						config.forwardToPort,
						requestURI.path,
						requestURI.query,
						requestURI.fragment)

			}

			next(Registry.single(proxyUri))
		}
	}
}
```

The handler builds a ```URI``` instance containing either the canary URI or the normal URI and then calls ```next``` but in this case, we pass the ```URI``` instance inside the registry to the last and final handler. New items can be added to a registry which allows a downstream handler to change it's behavior. 

In order the use the URI added to the registry, the ```ProxyHandler``` had to be changed slightly.

```groovy
class ProxyHandler extends GroovyHandler {
	@Override
	protected void handle(GroovyContext context) {
		context.with {
			HttpClient httpClient = context.get(HttpClient)
			URI proxyUri = context.get(URI)

			httpClient.requestStream(proxyUri) { RequestSpec spec ->
				spec.headers.copy(request.headers)
			}.then { StreamedResponse responseStream ->
				responseStream.forwardTo(response)
			}
		}
	}
}
```

The only change here is that the handler retrieves an instance of ```URI``` from the registry rather than building one from the configuration instance. 

## Handler chain execution and ordering

The handler chain is probably the most critical piece of Ratpack to understand. Walking through what happens when a request is processed is a useful mental exercise. The chain is constructed in the ```ratpack.groovy``` script.

```
handlers {
    get('reverseProxyAdmin', AdminModule.configHandler())

    all ProxyModule.loggingHandler()
    all ProxyModule.blacklistHandler()
    all ProxyModule.canaryHandler()
    all ProxyModule.proxyHandler()
  }
```

Consider a request for ```/reverseProxyAdmin```. The first handler processed is the one created by ```get('reverseProxyAdmin', AdminModule.configHandler())```. In this case, the request path matches what was passed to the get method, and so the ```ConfigHandler.handle()``` method is executed. This method executes ```render handlebarsTemplate('reverseProxyAdmin.html', config: config)``` and never calls ```context.next()```. The handler chain stops executing the html rendered in that method is written as the response body text.  

Now consider a request for ```/randomUri```. The handler chain starts to execute and ```randomUri``` does not match ```/reverseProxyAdmin```, therefor ```ConfigHandler.handle()``` is not executed. The next handler in the chain was added by ```all ProxyModule.loggingHandler()```. So ```LoggingHandler.handle()``` is executed. That method *always* calls ```context.next()```. The next handler in the chain is the blacklist handler. That handler was also added for every request (via the ```all``` method) and so that handler executes. The handler chain continues to execute in this manner until a handler does not call ```context.next()```.  

What would happen if the handler chain was defined slightly differently?

```
handlers {
	all ProxyModule.loggingHandler()

    get('reverseProxyAdmin', AdminModule.configHandler())

    all ProxyModule.blacklistHandler()
    all ProxyModule.canaryHandler()
    all ProxyModule.proxyHandler()
  }
```

In the case of ```/reverseProxyAdmin```, the first handler processed is the one created by ```all ProxyModule.loggingHandler()```. The handler logs the request and then calls ```context.next()```. The next handler is now the ```ConfigHandler```, and because the path matches ```reverseProxyAdmin``` it is executed. Everything else is the same. Order is important when constructing the handler chain. Changing the handler order will change behavior.

## Next time. 

In the next post I'll talk about creating a service layer to delegate functionality to from handlers, unit testing handlers and persistence using JOOQ.








