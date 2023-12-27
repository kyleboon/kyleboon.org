---
layout: post
title: "Ratpack plus Docker plus Gradle"
date: 2014-08-14 07:25
comments: true
categories: ratpack docker gradle
---

This is just a quick example of having gradle build a docker container with
a ratpack application as part of the build process. You'll need to have docker installed in order for this to work. If you're using OSX then [boot2docker](https://boot2docker.io/) is the best way to go.

Eventually I want to have gradle publish the docker container after a successful build of the master branch. Then I can use elastic beanstalk deploy the container with very little effort. 

First, add the shadow and docker plugins to your ratpack build.

```
buildscript {
    repositories {
        jcenter()
        maven { url "https://oss.jfrog.org/repo" }
    }
    dependencies {
        classpath "io.ratpack:ratpack-gradle:0.9.8-SNAPSHOT"
        classpath 'com.github.jengelman.gradle.plugins:shadow:1.0.3'
        classpath 'se.transmode.gradle:gradle-docker:1.2'

    }
}

apply plugin: "io.ratpack.ratpack-groovy"
apply plugin: 'com.github.johnrengelman.shadow'
apply plugin: 'docker'
```

The docker plugin can generate a docker file itself, but I prefer to write my own. I include the Dockerfile in the root directory of then project.

```
FROM ubuntu:14.04
MAINTAINER Kyle Boon<kyle@cellarhq.com>

# Prerequisites
run apt-get update
run apt-get install -y software-properties-common

# Install Java 8
run add-apt-repository -y ppa:webupd8team/java
run apt-get update
run echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
run apt-get install -y oracle-java8-installer

WORKDIR /app

USER daemon

# this file is copied to build/docker along with the cellarhq.com-all.jar. 
# if you run docker build . from the command line, you need to either copy
# the jar to the current directory after running gradle shadowJar
# or update this to build/libs/cellarhq.com-all.jar
ADD cellarhq.com-all.jar /app/build/libs/cellarhq.com-all.jar

CMD ["java", "-jar", "/app/build/libs/cellarhq.com-all.jar"]

EXPOSE 5050
```

This is a pretty basic Dockerfile. It uses the ubuntu base image, installs jdk8, copies over the jar file for the ratpack shadow jar. 

The last thing to do is create a gradle task to build the docker imange and then make gradle build dependent on that task.

```
task cellarHqDocker(type: Docker) {
    dependsOn shadowJar
    applicationName = 'cellarhq'
    tagVersion = '0.1'
    dockerfile = project.file('Dockerfile')

    doFirst {
        addFile project.tasks.shadowJar.archivePath
    }
}

build.dependsOn cellarHqDocker
```

The docker task depends on the shadowJar task. It also sets the tag version and copies the shadow jar into the temporary working directory where docker is run from.

Now you can build the entire thing by running ```gradle build```.

```
:compileJava
:compileGroovy
:processResources
:classes
:jar
:assemble
:prepareBaseDir UP-TO-DATE
:shadowJar
:cellarHqDocker
Step 0 : FROM ubuntu:14.04
 ---> ba5877dc9bec
Step 1 : MAINTAINER Kyle Boon<kyle@cellarhq.com>
 ---> Using cache
 ---> 39f4aa451a74
Step 2 : run apt-get update
 ---> Using cache
 ---> 0c392216cb3d
Step 3 : run apt-get install -y software-properties-common
 ---> Using cache
 ---> b585c9a1a4b0
Step 4 : run add-apt-repository -y ppa:webupd8team/java
 ---> Using cache
 ---> d9f91b21e7e9
Step 5 : run apt-get update
 ---> Using cache
 ---> 128da986a070
Step 6 : run echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
 ---> Using cache
 ---> 9af21f07082e
Step 7 : run apt-get install -y oracle-java8-installer
 ---> Using cache
 ---> 66edf7e13617
Step 8 : WORKDIR /app
 ---> Using cache
 ---> 9afa83d6a595
Step 9 : USER daemon
 ---> Using cache
 ---> 9429ccca9c01
Step 10 : ADD cellarhq.com-all.jar /app/build/libs/cellarhq.com-all.jar
 ---> 57528f08037f
Removing intermediate container 715553936c1e
Step 11 : CMD ["java", "-jar", "/app/build/libs/cellarhq.com-all.jar"]
 ---> Running in 1e10e36650a3
 ---> a0fc5d6649cf
Removing intermediate container 1e10e36650a3
Step 12 : EXPOSE 5050
 ---> Running in 4f0b8fce6a37
 ---> a17d51546b8a
Removing intermediate container 4f0b8fce6a37
Step 13 : ADD cellarhq.com-all.jar /
 ---> b7a5c60eda4f
Removing intermediate container 8926ec0178ca
Successfully built b7a5c60eda4f

:codenarcMain
:codenarcTest SKIPPED
:compileTestJava UP-TO-DATE
:compileTestGroovy
:processTestResources
:testClasses
:test
:check
:build

BUILD SUCCESSFUL
```

The container is now available. ```docker images``` will show it.

```
docker images
REPOSITORY                  TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
com.cellarhq/cellarhq       0.1                 b7a5c60eda4f        2 days ago          856.3 MB
```

Run the docker container will start the ratpack service.

```
docker run com.cellarhq/cellarhq:0.1
```

That's it!

