---
layout: post
title: Two-Step Authentication - Part 1
date: 2014-04-10 12:00
comments: true
categories: grails spring-security 
published: false
---

Two-Step authentication is the process of having the user make two separate identiy verifications. I could write a long explanation here or just refer to you a [real explanation](http://en.wikipedia.org/wiki/Two-step_verification).  Creating a two-step authentication process with grails and spring security isn't terribly difficult. 

NB: There are probably multiple ways to do this with Spring Security. This is how we did with a legacy application that had many existing users and roles already.

This is going to be the first of a two part series because it's taking too long to write the entire aritcle at once. All of the code can be seen on [github](https://github.com/kyleboon/two-step-authentication-example) of course.

* Create a skelaton grails application
* Generate the spring security bootstrap to get started
* Add a seed user (I tried the Seed data plugin for the first time)