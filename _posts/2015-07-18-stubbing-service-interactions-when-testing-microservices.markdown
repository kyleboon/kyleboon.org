---
layout: post
title: Stubbing External Service Interactions using Ratpack
date: 2015-07-18 08:33
comments: true
categories: ratpack microservices testing spock 
---

Most modern web applications call an external service via http. Applications built on the increasingly popular micro service architecture use many external services. In a unit test it's easy to mock the http client. In integration or functional testing it is both more difficult to inject a mock, and less useful because typically in these tests you don't _want_ to mock the actual HTTP call. 

Ratpack has a method for embedding a tiny web service directly into your test. In a few lines of code you can write a real web service to return real data to your test. The best part is the embedded app starts up blazingly fast so you don't pay a sigificant penalty for using it. 

You can use this feature even if the application you're testing isn't build on Ratpack. if you're using a java or groovy test framework and JDK8, you can take advantage of Ratpack and it is a great way to introduce ratpack to your organization.

Here's an example testing a Grails3 application that is calling the Github api to render a list of pull request titles.

```groovy
class GithubController {

    String githubApiURL = grailsApplication.config.getProperty('githubApi')

    def index() {
        String githubApiURL = grailsApplication.config.getProperty('githubApi')
        def restClient = new RESTClient(githubApiURL)
        def grailsPullRequestURL = "repos/grails/grails-core/pulls"

        try {
            def response = restClient.get(path: grailsPullRequestURL, contentType: 'application/json')

            if (response.status > 200) {
                render status: 500
            } else {
                render response.data*.title as JSON
            }
        } catch (all) {
            render status: 500
        }

    }
}
```

And here's a spock integration test that calls ```https://localhost:8080/github/```. Then the embdedded ratpack app stubs out the github response and allows the test to assert on the result. There's also an example test for ensuring errors from github would be appropriately handled.

```groovy
@Integration
@Rollback
class GithubControllerSpec extends Specification {
    RESTClient restClient
    def grailsApplication

    def setup() {
        restClient = new RESTClient("https://localhost:8080/")

    }

    void "list some pr titles correctly"() {
        given:
        EmbeddedApp github = GroovyEmbeddedApp.of {
            handlers {
                all {
                    render '[{"title": "pr1"}, {"title": "pr2"}, {"title": "pr3"}]'
                }
            }
        }

        grailsApplication.config.githubApi = "https://${github.address.host}:${github.address.port}"

        when:
        def response = restClient.get(path: "github/", contentType: 'application/json', requestContentType: 'application/json')

        then:
        response.status == 200
        response.data == ['pr1', 'pr2', 'pr3']
    }

    void "handle 500 errors from github gracefully"() {
        given:
        EmbeddedApp github = GroovyEmbeddedApp.of {
            handlers {
                all {
                    getResponse().status(500)
                    render '[]'
                }
            }
        }

        grailsApplication.config.githubApi = "https://${github.address.host}:${github.address.port}"

        when:
        def response
        try {
            restClient.get(path: "github/", contentType: 'application/json', requestContentType: 'application/json')
        } catch (all) {
            response = all.response
        }

        then:

        response.status == 500
    }
}
```