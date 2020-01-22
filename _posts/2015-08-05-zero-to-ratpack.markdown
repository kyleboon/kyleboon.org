---
layout: post
title: Zero to Ratpack
date: 2015-08-05 10:56
comments: true
categories: ratpack
---
# Introduction

There is a lot of interest in [Ratpack](http://ratpack.io/) after the gr8conf conference season and a question I heard multiple times was "What's the use case for Ratpack?". It's a great question. The main advantages of Ratpack to me are:

* Designed from the ground up to be modern Java. Reading the source is a great way to see how Java should be written in 2015. 
* Asynchronous and non blocking at the core. Ratpack has a pool of worker threads to execute blocking code separate from the threads that handle requests. Understanding your application to the point of knowing what code is blocking on IO or computation is critical for writing performant applications. Using higher abstraction frameworks makes it easy to forget what is really happening inside your application. You can see how core this is to the Ratpack API by looking at the [Session interface](http://ratpack.io/manual/current/api/index.html) or [Request.getBody method](http://ratpack.io/manual/current/api/index.html) which returns a promise.
* The handler chain is an interesting and powerful way to compose functionality.

I have code in 3 production Ratpack applications. One of them is a traditional web application serving some REST web services and some HTML. The other two are micro-services built on Ratpack and Cassandra. Both of these are easy to implement in Ratpack.

A lot of frameworks these days have a sort of 'canonical' use case that many people build as a type of hello-world introduction to the framework. Rails and Grails had the blog example, Javascript MVC frameworks like Angular often use the to-do app example and I've seen elixir use a real time chat application. Naturally Ratpack can build any of these applications, but I wanted to write a series of blog posts explaining how to build a Ratpack app from the ground up that would show off some of the unique features of Ratpack. I decided on a reverse proxy with features like traffic logging and authentication. It will show off the non-blocking, streaming, configuration and composable handler chain that makes Ratpack really interesting to me. Naturally after I decided this, I found that Rus Hart, Ratpack core team member, [had the idea first](https://gist.github.com/rhart/eb1b701f348a155f2dad). Never the less this is part 1 of N in building a Reverse Proxy with Ratpack. 

# What is a reverse proxy?

A reverse proxy takes a request from a client and then makes a request to one or more server to retrieve the requested resource and then returns that resource to the original client. This is what nginx does if you're familiar. Read [wikipedia](https://en.wikipedia.org/wiki/Reverse_proxy) for a better explanation. 

# Getting Started

I'm assuming you have Java8 installed and are familiar with java, groovy and gradle. Having GVM and lazybones installed is recommended. 

```bash
lazybones create ratpack ratpack-reverse-proxy --with-git
```

Lazybones is the easiest way to bootstrap an empty, working Ratpack application. If you don't have lazybones installed and don't want to, then create the following folder structure. You can also clone the [github repo](https://github.com/kyleboon/ratpack-reverse-proxy) for this project. Checkout the tag 'POC' for the code related to this post.

```
.
├── README.md
├── build.gradle
├── gradle
│   └── wrapper
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
├── gradlew
├── gradlew.bat
└── src
    ├── main
    │   └── groovy
    ├── ratpack
    │   ├── public
    │   │   ├── images
    │   │   │   └── favicon.ico
    │   │   ├── index.html
    │   │   ├── lib
    │   │   ├── scripts
    │   │   └── styles
    │   ├── ratpack.groovy
    │   └── templates
    │       └── index.gtpl
    └── test
        └── groovy
```

Run ```gradle run``` to see the skelaton start up. This will prove everything is installed correctly. Browse to ```http://localhost:5050/``` and you should see the page redirect to index.html. Try ```http://localhost:5050/about``` and see what happens. Remember what happens, it will be relevant.

# Proof of Concept

Now lets make this a proof of concept for a reverse proxy. Just for fun, this will reverse proxy cellarhq.com. Replace the contents of ```ratpack.groovy``` with the following:

```groovy
import ratpack.http.client.HttpClient
import ratpack.http.client.RequestSpec
import ratpack.http.client.StreamedResponse

import static ratpack.groovy.Groovy.ratpack

ratpack {
  handlers {
    all { HttpClient httpClient ->
      URI proxyUri = new URI(request.rawUri)
      proxyUri.host = 'www.cellarhq.com'
      proxyUri.scheme = 'https'
      httpClient.requestStream(proxyUri) { RequestSpec spec ->
        spec.headers.copy(request.headers)
      }.then { StreamedResponse responseStream ->
        responseStream.send(response)
      }
    }
  }
}
```

Run this with ```gradle run``` again and browse to ```http://localhost:5050/``` again and you'll see the CellarHQ home page. Click around, the links actually work as well. All the requests to localhost are being proxied to cellarhq by our little app. Try ```http://localhost:5050/about``` specifically and notice you get an actual page this time. The original application was only handling requests to the root. This application is handling requests for any path. 

# Some core concepts

There isn't a lot of code but it is a nice introduction to some core Ratpack concepts. The [handler chain](http://ratpack.io/manual/current/handlers.html) is the most important of these. All requests are processed by the handler chain. Each handler is simply a function which either responds to the request, or does some work and delegates to another handler. Our handler chain is a single function which is passed to the ```all``` method. This indicates that every request will be processed by this handler.  In the hello-world example generated by lazybones the ```get``` method was used, which processes only HTTP GET requests for `/`. 

The closure passed to the all method, our one and only handler, takes an ```HttpClient``` as parameter. However, an HttpClient is never explicitly created in our example. This is because the instance of HttpClient is created and managed by Ratpack itself. It is stored the [Registry](http://ratpack.io/manual/current/launching.html#registry) which is a store of objects by type. Ratpack ships with support for Guice and Spring when you need to add a DI library on top of the registry. Ratpack takes care of passing objects from the registry to Handlers.

Finally let's examine the meat of handler for a moment. 

```groovy
httpClient.requestStream(proxyUri) { RequestSpec spec ->
    spec.headers.copy(request.headers)
}.then { StreamedResponse responseStream ->
    responseStream.send(response)
}
```

Here you can start to see the asynchronous API that Ratpack is built on. The HttpClient is non blocking already, and the requestStream method returns a ```Promise```. Ratpack has its own promise api that is very easy to use. In this case we're streaming the response to the client upon completion of the promise. That's the ```then``` method.  It's important to know that the ```HttpClient``` is already non-blocking so we don't have to do anything to account for blocking code in this handler chain. If the handler needed perform database or file IO, then we would explicitly call out the blocking code and allow Ratpack to schedule that work on a different thread. 

# Conclusion of Part 1

This was just a proof of concept and example of building a very simple, not fully functional reverse proxy with Ratpack. It introduced some core concepts but left a lot unexplained. In the next post we will turn the proof of concept into a 'real' application and cover configuration, logging, and look at how a Ratpack application is structured for a non trivial (though still simple) example.

If you're interested in seeing a medium sized application built on Ratpack, feel free to look at [CellarHQ](https://github.com/CellarHQ/cellarhq.com) which is a beer inventory management system for beer nerds like myself. *NB: At the time of this writing, the CellarHQ code is slightly behind the current Ratpack version and doesn't include all the pre 1.0 API changes.*


