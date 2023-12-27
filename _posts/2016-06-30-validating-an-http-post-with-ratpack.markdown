---
layout: post
title: Validating An HTTP POST With Ratpack
date: 2016-06-30 13:39
comments: true
categories: ratpack groovy
---

I do a lot of work with both ratpack and dropwizard for [SmartThings](https://www.smartthings.com). [Dropwizard](https://www.dropwizard.io/) has a lot more opinions than Ratpack does out of the box, but they're opinions I've grown used to and that I mostly agree with. I wanted validation in Ratpack to work as similarly as it does in Dropwizard.

## Requirements

* Use JSR-303 
* Be (mostly) automatic. I didn't want to add much code to each handler to validate and send the error response
* Not use exceptions for flow control. 

## Solution

The solution is pretty simple and it uses the [`Promise.route`](https://ratpack.io/manual/current/api/ratpack/exec/Promise.html#route-ratpack.func.Predicate-ratpack.func.Action-) method to short circuit the promise chain and call `clientError(int statusCode)` immediately. Here's a complete example.

```java
import org.apache.http.HttpStatus
import org.hibernate.validator.constraints.NotEmpty
import ratpack.exec.Promise
import ratpack.handling.Context
import ratpack.jackson.Jackson

import javax.validation.Validation
import javax.validation.Validator
import javax.validation.constraints.NotNull

import static ratpack.groovy.Groovy.ratpack

class Widget {
	@NotNull
	@NotEmpty
	String name
}

ratpack {
	bindings {
		bindInstance(Validator, Validation.buildDefaultValidatorFactory().validator)
	}

	handlers {
		post("widget") {
			parseAndValidate(context, Widget)
					.map(Jackson.&json)
					.then(context.&render)
		}
	}
}

private <T> Promise<T> parseAndValidate(Context ctx, Class<T> type) {
	return ctx.parse(Jackson.fromJson(type)).route({ T obj ->
		return (ctx.get(Validator).validate(obj).size() > 0)
	}, {
		ctx.clientError(HttpStatus.SC_UNPROCESSABLE_ENTITY)
	})
}
```

```java
plugins {
    id 'io.ratpack.ratpack-groovy' version '1.3.3'
    id 'com.github.johnrengelman.shadow' version '1.2.3'
}
 
repositories {
    jcenter()
}
 
dependencies {
    compile 'org.hibernate:hibernate-validator:5.2.2.Final'
}
```


The ```parseAndValidate``` function parses the json just like you would normally o, then it calls the `route` method on promise and validates the the POGO using the Hibernate Validator. If there are any validation errors, `route` will short-circuit the promise chain and call clientError with a 422 status code. 

This is solution is similar to the Mr. Haki article [Ratpacked: Validating Forms: Validating Forms](https://mrhaki.blogspot.com/2015/11/ratpack-validating-forms.html)