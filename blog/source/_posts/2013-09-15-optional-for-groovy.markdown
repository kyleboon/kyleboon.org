---
layout: post
title: Optional Type for Groovy
date: 2013-09-15 08:09
comments: true
categories: groovy
---
The Optional type allows a programmer to specify intent on the retrun value of a method by specifying that the method could return an$ instance or null. It forces the caller to think about null and what that means. Functional languages like haskell and scala have this baked into the language. Java has an implementation in Google's Guava library and it will be included as a part of Java8. The pattern is related to Null Object but instead of being a specific implemantation of a type, it is a general purpose type that holds null or an instance.

A null return value could mean a lot of different things. It could be a correct response, intended by the developer to mean nothing needed to happen. It could indicate an error, that an insta/nce could not be created. Or, it could be an actual error that went undetected. In groovy we have the null safe operator which makes things easy! Unfortunately it can also lead to defaulting to use the null-safe operator without really undersanding *why* the value is null. This is a form of addressing the symptom of the problem rather than the cause of the problem. 

So, using an Optional type can help avoid this by forcing programmers to consider intent. Guava is heavy library if you're not already dependent on it. Java8 has an implementation but it lacks some conveniences groovy developers are accostumed to.  [Rob Fletcher](https://twitter.com/rfletcherEW) and I discussed it on twitter and I wrote a quick groovy implementation based on the Java8 Optional implementation. It has a few advantages over the java version:

* It implements asBoolean() so that you can use the shorthand in boolean predicates.
* It delegates to the reference using methodMissing and returns the result. (Using the null-safe operator)
* It adds an ifPresent(Closure c) method that returns the result of the closure if the reference exists.

These features allow you to use Optional in a slightly groovier way. What do you think, does groovy need an Optional type?

### References:

* [Java 8 Optional type](http://download.java.net/jdk8/docs/api/java/util/Optional.html)
* [Guava's discussion of null and when to avoid it](https://code.google.com/p/guava-libraries/wiki/UsingAndAvoidingNullExplained)
* [Stack overflow discussion of Optional](http://stackoverflow.com/questions/9561295/whats-the-point-of-guavas-optional-class)
* [Optional pattern](http://en.wikipedia.org/wiki/Option_type)

{% gist kyleboon/6567111 %}
