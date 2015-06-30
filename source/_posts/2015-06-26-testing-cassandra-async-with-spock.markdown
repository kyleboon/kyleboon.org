---
layout: post
title: Testing Cassandra using Spock
date: 2015-06-26 13:24
comments: true
categories: grails cassandra testing
---

We often use asynchronous execution of writes to cassandra tables. These methods return as soon as the call to cassandra is made which makes testing them a pain. I was resorting to adding a half second sleep after the method call before verifying the result in an integration test, but that was very fragile and would fail occassionally in our CI envrionment. 

###Example Cassandra Method
```groovy
void deleteSubscriptions(EventSource subscriberSource, String subscriberId) {
		log.debug("Deleting subscriptions by subscriber subscriberType: ${subscriberSource}, sourceId: ${subscriberId}")

		BoundStatement boundStatement = deleteBySubscriber.bind()
		boundStatement.setString("subscriberType", subscriberSource.name())
		boundStatement.setString("subscriberId", subscriberId)

		CQLSessionService.session.executeAsync(boundStatement)
}
``` 

###Test Example
```groovy
        when: "the events are deleted"
        cassandraEventSubscriptionService.deleteSubscriptions(
                eventSubscription.subscriberType,
                eventSubscription.subscriberId)

        and: "the subscriptions are retrieved by source"
        // this may be brittle because the delete is happening asynchronously
        sleep(500)

        Observable<EventSubscription> deletedBySource = cassandraEventSubscriptionService.findAllBySource(
                eventSubscription.sourceType,
                eventSubscription.sourceId,
                eventSubscription.data)

        and: "the subscriptions are retrieved by subscriber"
        Observable<EventSubscription> deletedBySubscriber = cassandraEventSubscriptionService.findAllBySubscriber(
                eventSubscription.subscriberType,
                eventSubscription.subscriberId)

        then: "the persisted subscription list has the original event subscription persisted"
        deletedBySubscriber.toList().toBlocking().first() == []
        deletedBySource.toList().toBlocking().first() == [eventSubscription2]
    }
```
#Solution

I wanted a way to retry test conditions without [retrying the entire test](https://github.com/anotherchrisberry/spock-retry). At first I thought spock [async conditions](http://spockframework.github.io/spock/javadoc/1.0/spock/util/concurrent/AsyncConditions.html) might help, but I misunderstood how they worked. So I decided to write a retriable condition.

This allows you to retry specific then conditionals. Pass a closure to the ```retry``` method along with a number of retries to execute and optionally an amount of time to pause between executions. The closure *must* make explicit calls to assert. If all attempts and trying the conditions fail, the final assertion failure will bubble up as the test failure reason.

```java
public class RetriableCondition {
	private final ConcurrentLinkedQueue<Throwable> exceptions = new ConcurrentLinkedQueue<Throwable>();

	public RetriableCondition() {
	}

	/**
	 * Evaluates the specified block, which is expected to contain
	 * one or more explicit conditions (i.e. assert statements).
	 * Any caught exception will be rethrown.</tt>.
	 *
	 * @param block the code block to evaluate
	 */
	@ConditionBlock
	public void retry(int times, int pauseInMilliseconds, Runnable block)
			throws SpockAssertionError, InterruptedException {
		for(int i=0;i<times;i++) {
			try {
				block.run();
				return;
			} catch (Throwable t) {
				exceptions.add(t);
				sleep(pauseInMilliseconds);
			}
		}

		String msg = String.format("Retried block %d times and it failed every time,", times);
		throw new SpockAssertionError(msg, exceptions.poll());
	}

	/**
	 * Evaluates the specified block, which is expected to contain
	 * one or more explicit conditions (i.e. assert statements).
	 * Any caught exception will be rethrown.</tt>.
	 *
	 * @param block the code block to evaluate
	 */
	@ConditionBlock
	public void retry(int times, Runnable block) throws SpockAssertionError, InterruptedException {
		retry(times, 0, block);
	}
}
```

###Updated Test Condition
```groovy
 then: "the persisted subscription list has the original event subscription persisted"
        condition.retry(5) {
	        Observable<EventSubscription> deletedBySource = cassandraEventSubscriptionService.findAllBySource(
			        eventSubscription.sourceType,
			        eventSubscription.sourceId,
			        eventSubscription.data)

	        Observable<EventSubscription> deletedBySubscriber = cassandraEventSubscriptionService.findAllBySubscriber(
			        eventSubscription.subscriberType,
			        eventSubscription.subscriberId)

	        assert deletedBySubscriber.toList().toBlocking().first() == []
	        assert deletedBySource.toList().toBlocking().first() == [eventSubscription2]
        }
```

### Example failure message
```
| Running 1 integration test... 1 of 1
| Failure:  can save, find and delete cassandra subscriptions(physicalgraph.event.cassandra.CassandraEventSubscriptionServiceIntegrationSpec)
|  Retried block 5 times and it failed every time,
    at physicalgraph.RetriableCondition.retry(RetriableCondition.java:33)
    at physicalgraph.event.cassandra.CassandraEventSubscriptionServiceIntegrationSpec.can save, find and delete cassandra subscriptions(CassandraEventSubscriptionServiceIntegrationSpec.groovy:50)
Caused by: Condition not satisfied:

bySource.toList().toBlocking().first() != [eventSubscription, eventSubscription2]
|        |        |            |       |   |                  |
|        |        |            |       |   |                  physicalgraph.event.cassandra.EventSubscription(DEVICE, 123, DEVICE, 789, switch.on, methodToCall, true, 2015-06-26T15:27:29.606-05:00)
|        |        |            |       |   physicalgraph.event.cassandra.EventSubscription(DEVICE, 123, DEVICE, 456, switch.on, methodToCall, true, 2015-06-26T15:27:29.589-05:00)
|        |        |            |       false
|        |        |            [physicalgraph.event.cassandra.EventSubscription(DEVICE, 123, DEVICE, 456, switch.on, methodToCall, true, 2015-06-26T15:27:29.589-05:00), physicalgraph.event.cassandra.EventSubscription(DEVICE, 123, DEVICE, 789, switch.on, methodToCall, true, 2015-06-26T15:27:29.606-05:00)]
|        |        rx.observables.BlockingObservable@10089d0a
|        rx.Observable@54e33280
rx.Observable@5588048e

    at physicalgraph.event.cassandra.CassandraEventSubscriptionServiceIntegrationSpec.can save, find and delete cassandra subscriptions_closure1(CassandraEventSubscriptionServiceIntegrationSpec.groovy:59)
    at physicalgraph.RetriableCondition.retry(RetriableCondition.java:25)
    ... 1 more
| Completed 1 integration test, 1 failed in 0m 1s
```
