---
layout: post
title: Optional Type for Groovy
date: 2013-09-15 08:09
comments: true
categories: groovy 
---
On my bikeride to work Friday I was thinking about Guava's optional type and whether or not I wanted to try to push for it to be used mored often at Bloom. The Optional type allows a programmer to specify intent on the retrun value of a method by specifying that the method could return a instance or null. It forces the consumer to think about null and what that means. In groovy we have the null safe operator which makes things easy! Unfortunately it can also lead to defaulting to use the null-safe operator without really undersanding why the value is null and should the value be null. 

A null return value could mean a lot of different things. It could be a correct response, intended by the developer to mean nothing needed to happen. It could indicate an error, that an instance could not be created. I've seen, and probably been guilty of:

```groovy
// this should never happen
return null
```

Invariably, that will happen at some point and the consumer of that method won't know what to do. Ideally, an exception would be raised there instead of returning null.

So, using an Optional type can help avoid these types of things but Guava's implementation seemed too.... Java-like. Rob Feltcher and I went back and forth about it on twitter and I wrote a quick groovy implementation based on the Java8 Optional implementation. It has a few advantages over the java version;

1: It implements asBoolean() so that you can use the shorthand in boolean predicates.
2: It delegates to the reference using methodMissing and returns the result. (Using the null-safe operator)
3: It adds an ifPresent(Closure c) method that returns the result of the closure if the reference exists.

These features allow you to use Optional in a slightly groovier way. Waht do you think, does groovy need an Optional type?

{% gist kyleboon/6567111 %}
