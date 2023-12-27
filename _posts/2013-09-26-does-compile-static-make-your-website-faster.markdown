---
layout: post
title: Does @CompileStatic make your web site faster?
date: 2013-09-26 21:37
comments: true
categories: groovy dropwizard load-testing 
---

At Bloomhealth we've been running five dropwizard in production for about 6 months. Until recently those services have mostly been for internal tools or low volume external tools. In preparation for heavier use, we started do more extensive load testing of both our grails and dropwizard applications. We've been using [gatling](https://wwww.gatling-tool.org/)   which is a load/performance testing tool in scala. You can write tests using a simple DSL or use a browser based scenario recorder for more complicated workflows. 

I started to wonder if using Groovy 2's static compilation feature would impact the performance of our dropwizard web services in a significant way. I've seen several benchmarks (listed at the end) that demonstrate a dramatic performance benefit with groovy's static compilation but I haven't seen anyone show the same for a production web service.  

## Goal

The goal was simply to see if it is worth exploring static compilation in a more thorough manner. Call it a 'spike'.

## Test Design

I used the latest build of a single dropwizard service and then took the same service and added ```@CompileStatic``` to every class. Overall about 70 classes were affected. There were a handful of compilation errors and test failures that I had to work through but nothing that required rewriting entire methods or classes. I did file one bug against groovy and am trying to write a failing unit test to prove another bug I found in this process. 

The way our service tests work is they hit each endpoint 10 times in 10 seconds and record all the metrics. Then it increases the number of requests by 10 over and over until the 95th Percentile is over 1 second. I ran the tests 3 times against the static and non statically compiled service. All the tests hit their 'breaking' point at the 220 request level. The following table has the averaged statistics across all 3 test runs.

<table width='100%' border='1px' border-style:'solid'>
    <tr>
      <td>Test Name</td>
      <td>Min</td>
      <td>Max</td>
      <td>Mean</td>
      <td>Std Deviation</td>
      <td>95th Percentile</td>
      <td>99th Percentile</td>
    </tr>
    <tr>
      <td>Dynamic Compilation</td>
      <td>10</td>
      <td>1610</td>
      <td>438</td>
      <td>446</td>
      <td>1350</td>
      <td>1550</td>
    </tr>
    <tr>
      <td>Static Compilation</td>
      <td>10</td>
      <td>1490</td>
      <td>413</td>
      <td>421</td>
      <td>1290</td>
      <td>1490</td>
    </tr>
</table>
* All times in milliseconds

## Conclusions

Every statistic showed improvement on all 3 test runs, but the overall impact was smaller than I originally hoped for. Also I only tested a single endpoint that didn't contain much business logic. Also there was a 6% improvement in the mean and 5% in the 95th percentile and I think that's a worthwhile improvement to make. Particularly if it doesn't require rewriting the code at all. The next step is to clean up some of my changes and test this build in our load testing environment in amazon with more load for a longer duration against more end points. 

## References
* [Static Complication Benchmarks](https://code.google.com/p/jlabgroovy/wiki/Benchmarks)
* [Stack Overflow Groovy Benchmarks](https://stackoverflow.com/questions/11344412/what-is-the-performance-of-groovy-2-0-with-static-compilation)
* [Java, Groovy, Kotlin performance comparisonn](https://objectscape.blogspot.de/2012/08/groovy-20-performance-compared-to-java.html)
* [Yet Another comparisonn](https://java.dzone.com/articles/java-7-vs-groovy-21)

