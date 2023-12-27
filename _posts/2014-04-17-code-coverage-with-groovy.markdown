---
layout: post
title: The State of Code Coverage for Groovy
date: 2014-04-17 13:25
comments: true
categories: groovy coverage jacoco cobertura
---

Last year we finally decided to update from JDK6 to JDK7. This was mostly a painless process, however when we upgraded, we started getting very strange code coverage numbers. We were using cobertura 2.0.3 at the time. I also created [an issue](https://github.com/cobertura/cobertura/issues/101) at the time, and more recently a [second issue](https://github.com/cobertura/cobertura/issues/135) was added.

Recently we started looking in to getting our coverage statistics working again so I've done a bit more digging with [John Engleman](https://imperceptiblethoughts.com/). We've tried [jacoco](https://www.eclemma.org/jacoco/) 0.7.0.201403182114, [cobertura](https://cobertura.github.io/cobertura/) 2.0.3 and [clover](https://www.atlassian.com/software/clover/overview) 3.1.12.1. 

I wanted to do an apples to apples comparison of jacoco and cobertura for JDK6 and JDK7 on a [simple groovy project](https://github.com/kyleboon/groovy-code-coverage-examples).

The project has one class:

```groovy
class CodeCoverageExample {
	def usedMethod(def a) {
		if (a) {
			dispatchToPrivateMethod()
		} else {
			dispatchToPrivateMethod2()
		}
	}

	def unusedMethod(def a) {
		if (a) {
			dispatchToPrivateMethod()
		}
	}

	private def dispatchToPrivateMethod() {
		1
	}

	private def dispatchToPrivateMethod2() {
		2
	}

}
```

It also has one test:

```groovy
import spock.lang.Specification

class CodeCoverageExampleSpec extends Specification {
	def "calls usedMethod"() {
		setup:
		CodeCoverageExample cce = new CodeCoverageExample()

		expect:
		result == cce.usedMethod(givenValue)

		where:

		result | givenValue
		1      | true
		2      | false
	}
}
```

Here are some statisics:

<table width='100%' border='1px' border-style:'solid'>
	<tr>
		<td>JDK Version</td>
		<td>Coverage Tool</td>
		<td>LOC covered</td>
		<td>Branches covered</td>
		<td>Comments</td>
	</tr>
	<tr>
		<td>6</td>
		<td>Cobertura</td>
		<td>71%</td>
		<td>25%</td>
		<td>This seems pretty legit to me.</td>
	</tr>
	<tr>
		<td>7</td>
		<td>Cobertura</td>
		<td>42%</td>
		<td>12%</td>
		<td>This is so broken. It didn't count any line in the private methods, and also didn't count a line hit inside the else branch.</td>
	</tr>
	<tr>
		<td>6</td>
		<td>jacoco</td>
		<td>50%</td>
		<td>21%</td>
		<td>Jacoco is saying 50% of instructions were executed but no lines of code had 100% of their instructions executed. I don't know how to determine what instructions were missed and if they are important.</td>
	</tr>
	<tr>
		<td>7</td>
		<td>jacoco</td>
		<td>50%</td>
		<td>21%</td>
		<td>Hurray consistency!</td>
	</tr>
	<tr>
		<td>6</td>
		<td>clover</td>
		<td>78%</td>
		<td>69%</td>
		<td>I had to calculate these percentages by hand using the XML data. </td>
	</tr>
	<tr>
		<td>7</td>
		<td>clover</td>
		<td>78%</td>
		<td>69%</td>
		<td>Hurray consistency! However Clover doesn't work on our non-trivial codebase and errors on classes with @CompileStatic. I couldn't reproduce this in my trivial example however.</td>
	</tr>
</table>

Honestly none of these are perfect. Clearly cobertura doesn't work for groovy on the jdk7. The instrumented code appears correct to my eyes but I am (obviously) not an expert. I don't really like the jacoco instructions measure because I don't understand where some of the missing instructions are and if they are important. Clover isn't opensource, is fairly expensive, and also doesn't work on our real applications. 

Jacoco seems to be the best option right now, but I'm hoping the cobertura defects are fixed soon.