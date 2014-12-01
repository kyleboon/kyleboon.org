---
layout: post
title: "Traits And Geb"
date: 2014-10-11 17:57
comments: true
categories: 
---

Traits were added to groovy in 2.3 and I hadn't used one yet in a real project. While writing some geb tests for a ratpack application recently, I needed to be able to log in as a user before the test executed. I wanted to reuse the log in code for other tests and decided a trait was a nice solution.

Why a trait and not a base class?

* Adding the trait to the spec that needs it marks that test very explicitly as one which logs in a user first. 
* It is composable with other traits I may add

Here is the trait itself:
 

```groovy
trait  LogInUserTrait {
    EmailAccount anEmailAccountUser(RemoteControl remote, String screenName, String email, String password) {
        remote.exec {
            Cellar cellar = new Cellar(screenName: screenName, displayName: screenName)
            EmailAccount emailAccount = new EmailAccount(email: email, password: password)
            emailAccount.cellar = cellar
            get(com.cellarhq.services.AccountService).create(emailAccount, null)
        }
    }

    void cleanUpUsers(RemoteControl remote) {
        remote.exec {
            try {
                Sql sql = new Sql(get(DataSource))
                sql.execute('delete from account_email where 1=1')
                sql.execute('delete from cellar_role where 1=1')
                sql.execute('delete from cellar where 1=1')
                sql.close()
            } catch (JdbcSQLException e) {
                // I don't think this should make the test fail: Will also be changed moving to jOOQ.
                log.error(e.message)
            }
        }

    }

    void logInUser(String email, String password) {
        LoginPage page = to LoginPage
        page.fillForm(email, password)
        page.submitForm()
    }

}
```

And here is the test which uses it:

```groovy
@Stepwise
@IgnoreIf({ SpecFlags.isTrue(SpecFlags.NO_FUNCTIONAL) })
class BreweriesFunctionalSpec extends GebReportingSpec implements LogInUserTrait {
    @Shared
    ApplicationUnderTest aut = new CellarHqApplication()

    @Shared
    RemoteControl remote = new RemoteControl(aut)

    def setupSpec() {
        browser.baseUrl = aut.getAddress().toString()
        EmailAccount emailAccount = anEmailAccountUser(remote, 'someone', 'test@cellarhq.com', 'badpassword')
        logInUser('test@cellarhq.com', 'badpassword')
    }

    def cleanupSpec() {
        cleanUpUsers(remote)
    }

    def 'verify can get to an empty list page'() {
        when:
        to BreweriesPage

        then:
        at BreweriesPage
    }

    def 'can add a new brewery'() {
        when: 'Navigate to the add brewery page'
        AddBreweryPage addBreweryPage = to AddBreweryPage

        and: 'the form is filled it'
        addBreweryPage.fillForm()

        and: 'the form is submitted'
        addBreweryPage.submitForm()

        then: 'the show brewery page is displayed'
        at ShowBreweryPage
    }
}
```

Overall using traits were trivial. You do need to use the IntelliJ 14 EAP if you want IDE support. 


