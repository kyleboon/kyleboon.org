---
layout: post
title: "Using meta-annotations to DRY your groovy"
date: 2014-01-22 19:11
comments: true
categories: groovy annotations
---

When you're using grails every day you forget how much the grails conventions can keep your code DRY.  I love dropwizard and I don't mind hibernate (too much) but adding the same 3 or 4 annotations on every class gets old. Groovy 2.1.0+ has a feature to help with this called meta-annotations or annotation collections.  This feature replaces a single annotation with a collection of them at compile time. Take a hibernate entity like this one:

```
@CompileStatic
@Entity
@Table(name = 'user')
class UserEntity { ... }
```

Every one of our entities has these annotations on it.  You can define a meta-annotation which includes all of those annotations.

```
@CompileStatic
@JPAEntity
@Table
@AnnotationCollector
@interface Entity { ... }
```

Then the user entity definition is reduced:

```
@Entity(name = 'user')
class UserEntity { ... }
```

The ```name``` attribute is then passed to every annotation in the ```@Entity``` annotation which has that property. In this case it is only the ```@JPAEntity``` annotation.

This technique not only lets you reduce some repeated code, but makes it easy to apply consistant changes to every class. If you decide you don't want to use static compilation anymore, just remove it from the meta-annotation. If you want to add a canonical constructor to every entity, just add ```@Canonical```. 

You can do more complicated things by defining your own collection processor.  Jersey resources are annotation heavy as well and it would be nice to reduce that. Here's a basic resource definition for a user resource:

```
@CompileStatic
@Slf4j
@Path('/users')
@Produces(MediaType.APPLICATION_JSON)
class UserResource extends AbstractResource { ... }
```

I want to define resources like this:

```
@DropwizardResource('/users')
class UserResource extends AbstractResource { ... }
```

Here's the meta-annotation:


```
@CompileStatic
@Slf4j
@Path
@AnnotationCollector(processor = 'com.bloomhealthco.radiant.service.resources.DropwizardResourceProcessor')
@interface DropwizardResource { ... }
```

I also wanted to add an ```@Produces``` annotation but that requires an enum passed to the value attribute and you can't do that in an annotation collection. So I defined an annotation collection processor to customize the path annotation and add the produces annotation at compile time.

```
class DropwizardResourceProcessor extends AnnotationCollectorTransform {
    private static final ClassNode PRODUCES_NODE = ClassHelper.make(Produces)
    private static final ClassNode MEDIATYPE_NODE = ClassHelper.make(MediaType)

    List<AnnotationNode> visit(AnnotationNode collector, AnnotationNode usage,
                               AnnotatedNode annotated, SourceUnit src) {
        List<AnnotatedNode> annotatedNodes = getTargetAnnotationList(collector, usage, src)

        AnnotationNode compileStaticNode = annotatedNodes[0]
        AnnotationNode logNode = annotatedNodes[1]

        Expression path = usage.getMember('value') ?: defaultPathExpression
        AnnotationNode pathNode = annotatedNodes[2]
        pathNode.addMember('value', path)
        usage.members.remove('value')

        AnnotationNode producesNode = new AnnotationNode(PRODUCES_NODE)
        producesNode.addMember("value", new PropertyExpression(new ClassExpression(MEDIATYPE_NODE), "APPLICATION_JSON"))

        return [compileStaticNode, logNode, pathNode, producesNode]
    }

    Expression getDefaultPathExpression() {
        return ConstantExpression.EMPTY_STRING
    }
}
```

This one requires a little more explanation since it's using an AST to rewrite the annotations on the class at compile time. The basic idea is to get build a new list of annotations and then return them from the ```visit()``` method.

```
AnnotationNode compileStaticNode = annotatedNodes[0]
AnnotationNode logNode = annotatedNodes[1]
```

First references are grabbed to the compile static and slf4j annotation nodes which aren't going to be changed at all.

```
Expression path = usage.getMember('value') ?: defaultPathExpression
AnnotationNode pathNode = annotatedNodes[2]
pathNode.addMember('value', path)
usage.members.remove('value')
```

The resource annotation ```@DropwizardResource('/users')``` provides a path which needs to be set on the value attribute of the ```@Path``` annotation. First the value attribute of the meta-annotation is found. If the usage doens't include a path, then it is set to an empty string expression. Then the value of the ```@Path``` annotation is set with the path expression. Finally the value from the usage of @DropwizardResource is removed so that it won't be reused by any other annotation.

```
AnnotationNode producesNode = new AnnotationNode(PRODUCES_NODE)
producesNode.addMember("value", new PropertyExpression(new ClassExpression(MEDIATYPE_NODE), "APPLICATION_JSON"))
```

This part is slightly trickier. A new annotation needs be constructed at compile time. This is necessary because the value passed to ```@Produces``` is an enum and meta-annotations don't support using enum values. ASTs make this reasonably easy but it is a little mind bending to understand the first few times.

```
return [compileStaticNode, logNode, pathNode, producesNode]
```

Finally the new list of annotations is returned and compilation continues. 

## Conclusions

Meta-annotations are a great way to reduce annotation duplication and make it a lot easier to make application-wide changes in a single place. They are also a good way to learn the basics of AST transformations. 

## References

* [Groovy meta-annotation documentation](http://groovy.codehaus.org/Meta-annotations)
* [Groovy Goodness: Combining Annotations with AnnotationCollector](http://mrhaki.blogspot.com/2013/02/groovy-goodness-combining-annotations.html)
* [Compile Time Metaprogramming - AST Transformations](http://groovy.codehaus.org/Compile-time+Metaprogramming+-+AST+Transformations)