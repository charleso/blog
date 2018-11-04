---
title: Talks
layout: page
---

## Caught in a Web of Functions

[_8 May 2017 @ YOW! LambdaJam_](https://lambdajam.yowconference.com.au/archive-2017/charles-ofarrell-2/)

Functional programming is a great tool for enabling programmers to solve complex
problems through the use of data and functions. However, not all data and
functions are created equal, and some are less composable than others. Web
libraries in particular are guilty of being overly opinionated and ending up as
closed worlds of functionality. As programmers we are complicit whenever we find
ourselves asking: “What web framework should I use”? But why do we need to
choose a single framework in the first place? Why can’t we compose functions
from different libraries? Do we really need 5 different ways to get/set a
cookie?

This talk aims to deconstruct what we typically expect from a web framework, and
how we can achieve the same functionality with a series of small, composable
functions. This will be demonstrated using Haskell’s WAI library as a common
building block, and contrasted to the equivalent implementation in other modern
Haskell web frameworks. By the end of this talk web frameworks will be
demystified and exposed for what they should be – a collection of composable
functions. In addition the audience will have gained confidence in their ability
to recognise good and bad functions, and to better evaluate the cost of the
libraries they inhabit.

- [Slide](https://charleso.github.io/lambdajam-web-functions/)
- [Video](https://www.youtube.com/watch?v=WhUFaZMFt6A)


## Property Testing: Finding More Bugs With Less Effort

- [_12 July 2017 @ ScalaSyd_](https://www.meetup.com/scalasyd/events/241392106/)
- [_18 July 2017 @ YOW! Night Singapore_](https://nights.yowconference.com.au/archive-2017/property-based-testing-finding-bugs-less-effort/)

Testing is an essential part of writing and maintaining correct and reliable
software. However, for the most part the best technique we have for writing
tests is to capture some examples in the hope that they cover all the known
edge cases. Unfortunately these examples almost always missing something.

What if we could ask the computer to generate these examples? Not just a
handful, but hundreds of them that we never even considered. It turns out we
can! By using the technique known as Property Based Testing.

This talk will explore the motivation and concepts behind this powerful testing
technique. We also introduce a number of simple but useful patterns that can be
applied again and again when writing properties. In addition this talk will
highlight a handful of compelling examples of Property Based Testing uncovering
nasty bugs in real world software.

Finally, apart from learning about why and how to use Property Based Testing to
write better software, the audience will also realise that testing can be made
more enjoyable in the process.

- [Slides](https://charleso.github.io/property-testing-preso/scalasyd-07-2017-find-more-bugs.html)
- [Video](https://www.youtube.com/watch?v=hP-VstNdFGo)


## Life Without Stacktraces

[_10 February 2016 @ ScalaSyd_](https://www.meetup.com/scalasyd/events/228487518/)

Standard programming techniques and debuggers have left us dependant on
stacktraces to give us an understanding of how our programs work. With async
continuations, trampolining, recursion and other programming techniques, the
stack no longer provides us with any useful information about calling context.
This talk will show how safe error handling can provide us with superior tools
for the purpose, and how to use them effectively.

- [Slides](http://charleso.github.io/life-without-stack-traces/)
- [Video](https://www.youtube.com/watch?v=47h0tBklycM)


## Practical property-based testing with ScalaCheck

[_21 May 2015 @ YOW! Lambda Jam_](https://lambdajam.yowconference.com.au/archive-2015/charles-ofarrell/)

At first it can be tricky working out how exactly you test your code with
properties. The good news is that there are some very obvious and useful
patterns that can make writing generators and properties easy by mere-mortals.

This talk aims to cover some of those patterns, and in doing so help both
people working or struggling with property-based testing, and through that to
also motivate the use of property-based testing for those still unfamiliar with
the concept.

- [Slides](http://charleso.github.io/property-testing-preso/yowlj2015.html)
- [Video](https://yow.eventer.com/yow-lambda-jam-2015-1305/practical-property-based-testing-by-charles-o-farrell-1884)


## Practical property-based testing with ScalaCheck

[_11 February 2015 @ ScalaSyd_](https://www.meetup.com/scalasyd/events/220240445/)

Property-based testing can be little daunting when you first start. Fortunately
there are few simple tricks/patterns that can open up a world of possibilities
for testing your code. These techniques also serve as good motivation for why
property-based testing is so damn useful.

- [Slides](http://charleso.github.io/property-testing-preso/)


## Scala: The Good Parts

[_12 November 2014 @ ScalaSyd_](https://www.meetup.com/scalasyd/events/217737682/)

An inside look into some of the best-practices of the Ambiata team as they
battle Scala in the trenches.

- [Slides](http://charleso.github.io/scala-the-good-parts/)


## Null is not an Option, Either are NPEs

[_12 September 2012 @ ScalaSyd_](https://www.meetup.com/scalasyd/events/80905832/)

- [Slides](https://bitbucket.org/cofarrell/cofarrell.bitbucket.org/src/master/optional/index.html)


## Shapeless

[_11 July 1012 @ ScalaSyd_](https://www.meetup.com/scalasyd/events/68806452/)

Charles O'Farrell will attempt to explain the inner workings of Miles Sabin's
brain and how he is pushing the frontier of polytypic programming in Scala with
the Shapeless library

- [Slides](http://charleso.github.io/scala-talk/shapeless/)


## Type Classes as Object and Implicits

[_8 February 2012 @ ScalaSyd_](https://www.meetup.com/scalasyd/events/47758132/)

What are type classes, how can they help and why can't we get them in stupid
ol' Java?

- [Slides](http://charleso.github.io/scala-talk/type-classes/)


## A Taste of Scala

[_29 August 2011 @ BrisJVM_](https://www.meetup.com/brisjvm/events/26374761/)

The talk will begin by covering the Scala syntax briefly and then delving into
some of the nicer features (type inference, functional programming, etc). It
will then concentrate on some specific things like Option and Case Classes to
hopefully highlight some immediate and easy wins over Java.

- [Video](http://vimeo.com/groups/qldjvm/videos/28291058)
- [Slides](http://charleso.github.io/scala-talk/)
