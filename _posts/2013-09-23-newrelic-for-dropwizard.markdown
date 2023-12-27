---
layout: post
title: Enabling Newrelic for Dropwizard
date: 2013-09-23 12:43
comments: true
categories: groovy dropwizard newrelic 
---

We are using Yammer Metrics and Graphite but New Relic gives a lot of fantastic information with very little work. We've used it for several years with our Grails applications. In particular, the app server transaction traces gives data that we don't get by default from yammer metrics. Enabling new relic is easy with dropwizard by following [New Relic's directions](https://newrelic.com/java). This really just boils down to adding the new relic java agent when you start dropwizard.

```bash
java -javaagent:/path/to/newrelic.jar -jar path/to/dropwizard server start config.yml
```

New Relic will just start collecting metrics after this but all the transactions will be named '/ServletContainer'. The URL will be included in the transaction trace but this level of data isn't granular enough for us. In our grails applications we named the transactions after the controller and action being executed by using the [New Relic API](https://newrelic.com/docs/java/java-agent-api) and a simple request filter. I wanted to find a similar solution for dropwizard.

### How It Works

Yammer Metrics uses a Request Dispatcher to hook in to Jersey. A Request Dispatcher is basically just a 'thing' that does some processing before a Resource Method is executed. There are three classes you need to implement to add a Request Dispatcher as a Jersey provider. I followed the pattern set by the ```UnitOfWorkRequestDispatcher``` in dropwizard-hibernate. You will also need to add the new relic api as a dependency. I am piggy backing on the ```@Timed``` yammer metrics annotation, so this functionality will be added to any Resource Method that is annotated with ```@Timed```.

A RequestDispatcher instance is created for each Resource Method when your service starts up. The RequestDispatchProvider looks at the resource and method name, creates the transaction name and then creates a RequestDispatcher instance with that transaction name. The RequestDispatchAdapter builds a RequestDispatchProvider. An instance of that class is added as Jersey provider when dropwizard starts up.

```groovy
compile 'com.newrelic.agent.java:newrelic-api:2.20.0'
```
Just adding the dependency.

```groovy
environment.addProvider(new TimedResourceMethodDispatchAdapter())
```
This should be in the run method if you dropwizard service.

```groovy
@Canonical
class TimedRequestDispatcher implements RequestDispatcher {
    final RequestDispatcher dispatcher
    final String transactionName

    @Override
    public void dispatch(Object resource, HttpContext context) {
      NewRelic.setTransactionName(null, transactionName)
      dispatcher.dispatch(resource, context)
    }
}
```
One instance of the TimedRequestDispatcher is created per Resource Method with the ```@Timed``` annotation. The name of transaction is provided to the dispatcher when it is created. Before dispatching, the New Relic API is called to set the transaction name. 

```groovy
@Canonical
class TimedResourceMethodDispatchAdapter implements ResourceMethodDispatchAdapter {
  @Override
  public ResourceMethodDispatchProvider adapt(ResourceMethodDispatchProvider provider) {
    return new TimedResourceMethodDispatchProvider(provider)
  }
}
```
This is the class that creates the Provider used by Jersey.

```groovy
@Slf4j
@Canonical
class TimedResourceMethodDispatchProvider implements ResourceMethodDispatchProvider {
    final ResourceMethodDispatchProvider provider

    @Override
    public RequestDispatcher create(AbstractResourceMethod abstractResourceMethod) {
      RequestDispatcher dispatcher = provider.create(abstractResourceMethod)
      Timed timed = abstractResourceMethod.method.getAnnotation(Timed)

      if (timed) {
        String resourceName = abstractResourceMethod.declaringResource.resourceClass.simpleName
        String methodName = abstractResourceMethod.method.name
        return new TimedRequestDispatcher(dispatcher, "${resourceName}/${methodName}")
      }
      return dispatcher
   }
}
```
The Provider is called for each Resource Method and creates the ```TimedRequestDipatcher``` if necessary. The transaction name is also created here.

### Other Stuff

This method would work for regular Jersey applications as well. The code is in groovy but it would be simple to turn it into Java.

### References

* [New Relic Java Agent API](https://newrelic.com/docs/java/java-agent-api)
* [Dropwizard Hibernate](https://github.com/dropwizard/dropwizard/tree/master/dropwizard-hibernate)
* [Jersey Request Dispatcher interface](https://jersey.java.net/nonav/apidocs/1.5/jersey/com/sun/jersey/spi/dispatch/RequestDispatcher.html)
* [Yammer Metrics Jersey Implementation](https://metrics.dropwizard.io/4.0.0/manual/jersey.html)

