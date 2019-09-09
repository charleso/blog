---
author: Charles O'Farrell
date: 2018/12/19 20:21:00
encoding: utf8
permalink: /2018/12/expression-tradeoff.html
categories: scala
title: The Expression Tradeoff
updated: 2018/12/19 20:21:00
layout: post
---

*NOTE: This is something I wrote for my team at BT, I'm not sure how generally
readable they will be for others*

Fortunately and unfortunately there are multiple ways of doing the same thing in
Scala. When it comes to "abstractions" unfortunately this can lead to us as
developers reaching for whatever is convenient at the time, rather than perhaps
what might be more correct and less error prone.

Firstly, there are really two very distinct ways of defining an abstraction,
each with different properties and trade-offs. They are very distinct even if
they are implemented in Scala language features that appear similar.

## Closed Types

A closed type is an abstraction where all different cases are known
and cannot be extended outside of a given file/module. This makes it cheap to
add new functions dealing with the type, all you need to do is pattern match
anywhere you like, but it's very expensive to add new constructors (see
[Expression Problem](#expression-problem) below for more reading).

This concept can be expressed in Scala by using the sealed trait language
feature. The implementation is sometimes referred to as using "sum types" from
[algebraic data-types](https://en.wikipedia.org/wiki/Algebraic_data_type) (or ADTs).

### Suggestion: Put constructors inside of the companion object for more convenient namespace scoping

```scala
sealed trait Category

object Category {

  case object Nominal extends Category
  case class Hostname(entropy: Int) extends Category
}
```

### Suggestion: Create constructor functions with the real "type"

Unfortunately the subtyping language feature in Scala can causes a great deal of
pain/problems when mixing these constructors. Especially with data types that
aren't covariant (ie don't have use a +). For example:

```
import scalaz._

type X[B] = \/[Category, B]
val value = for {
  _ <- EitherT.fromDisjunction[X](Category.Nominal.left[Unit])
  _ <- EitherT.fromDisjunction[X](Category.Hostname(1).left[Unit])
} yield ()
```

```
Error:(18, 9) type mismatch;
 found   : scalaz.EitherT[X,Category.Nominal.type,Unit]
 required: scalaz.EitherT[X,Category.Hostname.type,?]
      _ <- EitherT.fromDisjunction[X](Hostname(1).left[Unit])
```

The problem is that constructors have their own "type". When using invariant
data structures, such as scalaz's [EitherT] type above, the "real" parent type
*will not* be inferred by Scala. Scala needs a helping hand to bypass the default
subtyping behaviour.

[EitherT]: https://github.com/scalaz/scalaz/blob/v7.1.5/core/src/main/scala/scalaz/EitherT.scala#L15

```scala
object Category {

  def nominal: Category = Nominal
  def hostname(entropy: Int): Category = Hostname(entropy)
}
```

Yes, it's annoying having to write boilerplate, but it becomes essential to
avoid dealing with subtyping and confusing compiler errors.  The final working
example:

```scala
sealed trait Category

object Category {

  case object Nominal extends Category
  case class Hostname(entropy: Int) extends Category

  def nominal: Category =
    Nominal
  def hostname(entropy: Int): Category =
    Hostname(entropy)
}

val value = for {
  _ <- EitherT.fromDisjunction[X](Category.nominal.left[Unit])
  _ <- EitherT.fromDisjunction[X](Category.hostname(1).left[Unit])
} yield ()
```

### Rule: *Always* pattern match on every constructor

It's important that when using closed
types that you ensure future safety by pattern matching on every constructor.
The compiler is your friend and can help you or the next person adding or
changing constructors handle the new behaviour. Once you use a wildcard
(underscore) pattern match, all bets are off and you won't get any warning that
behaviour might need to change or be extended.

```
def isNominal(c: Category) =
  c match {
    case Nominal => true
    // Please don't do this, even if you think you won't ever care about new constructors, you just never know (and sadly you won't)
    case _ => false
  }
```

### [Visitor Pattern](https://en.wikipedia.org/wiki/Visitor_pattern)

It's unfortunate that most OO languages actually make this very powerful
abstraction very cumbersome to represent. On the flip side creating open types
via interfaces is bread-and-butter. To represent closed-types in OO one common
(but verbose) approach is the visitor pattern, which you can think of as
representing each constructor as a visitor method. This approach is not helped
that by default each visitor function return void, so consumers have to use
mutation to track things.

```scala
trait CategoryVisitor {

  def visitNominal: Unit
  def visitHostname(f: Int => Unit): Unit
}
```

There's no reason the visitor pattern couldn't be done like this:

```scala
trait CategoryVisitor[A] {

  def visitNominal: A
  def visitHostname(f: Int => A): A
}
```

This could be expressed more concisely as a single function with
values/functions for each constructor/visit:

```scala
trait Category {

  def visit[A](nominal: => A, hostname: Int => A): A
}
```

And if you squint this looks a lot like `foldRight` for `List`, which is because it
is! The visitor pattern is really just a verbose/clumsy way of doing a fold.
Which is just another way of pattern matching on each constructor of a given
ADT. *They're all the same thing!*

## Open Types

An open type is just something where consumers `anywhere` can create their own
instance anywhere, anytime. This makes it cheap to add new instances of the
type, just create a new instantiation and implement the required interface, but
it's *very* expensive to add new functions (see [Expression Problem](#expression-problem) below for more
reading).

```scala
trait UserService {

  def get(id: UserId): Option[User] }

class HadoopUserService extends UserService {
}
```

Unfortunately in traditional OO codebases it's very common to peek at what
specific instance (ie using `isInstanceOf` and `asInstanceOf`). This leads to
code bases that become more and more unmaintainable as various consumers start
to put bespoke logic for specific implementations of your abstraction, but that
information is not captured at the type-system level.

In short you've broken the "abstraction". The interface you originally specified
wasn't enough.

### Rule: Never check or cast the instance of an open type

The flip side of that
behaviour is adding more and more functions/behaviours to an abstraction. Here
is an example:

```scala
trait UserService {

  def get(id: UserId): Option[User]

  def getByIds(ids: List[UserId]): Map[Id, UserId]
}
```

We should try very hard to distinguish what is core functionality versus what
can be derived. In the example above we really have two ways of doing the same
thing, but now each implementation needs to re-implement the same logic, which
can lead to bugs. It also increases the surface of the abstraction/type which
is harder to reason about. It really isn't that hard to derive functions based
on the original one:

```
trait UserService {

  def getByIds(ids: List[UserId]): Map[Id, UserId] }

object UserService {

  def get(service: MyService, id: UserId): Option[User] =
    service.getByIds(List(id)).map(_.get(id))
}
```

In the example above there are actually two ways of "deriving" the extra
function. The more common way is to add an implementation function to the
interface. This is certainly convenient, but can lead to a very bloated
interface in a single file/module. It's also impossible to sneakily "override"
them if they're not marked as `final`. Having the functions live on the object
make it clear that they're derived, and can easily be moved to other modules,
or implemented in different ways. It forces you to think clearly about the real
"abstraction" and what it really provides vs what you can do with it.

### Case Class (Alternative Encoding)

Note that using the trait Scala language feature to implement an open type is
identical in concept to using a case class with function fields.

```
case class UserService( getByIds: List[UserId] => Map[Id, UserId])

object UserService {

  def hadoopUserService: UserService = UserService(...)
}
```

In some ways this is actually a "safer" way to encode the abstraction versus
using inheritance. This way there is literally no way to cast of check the
hadoopUserService implementation, you can only call the functions as given.

Choosing between the two approaches is really just a matter of taste, assuming
the important rules above are adhered to. Purely from a low-level,
raw-performance perspective using `trait` is a better approach as it takes
advantage of JVM optimisations around classes. This should only be relevant for
hot code paths and should only be refactored in conjunction with responsible
performance testing. Don't guess!

#### Mocking

An additional bonus of this approach is that you can "mock" functions
based on other behaviour. In the traditional OO approach mocking requires a
complex set of runtime/reflection hacks. If the functions are just data you can
manipulate them in difference ways.

```scala
def mockUserService: UserService =
  hadoopUserService.copy(getByIds = _ => Map())
```

*I don't suggest people actually use mocking like this*, but it's an interesting
benefit of not using the Scala OO language features.

## Further Reading

### [Expression Problem](https://en.wikipedia.org/wiki/Expression_problem)

The relationship between these two approaches has been described as the
"expression problem". The unfortunate thing about using the term "problem" is
that people then look for a "solution" and then claim to have found one. It
should probably be called the "expression tradeoff" but it's not as catchy.

### Variance Woes

It's hard to point to a single explanation exactly to what problems variance
causes in Scala. I'll try to add the best links I can find to the following
list.

- https://leanpub.com/fpmortals/read#leanpub-auto-type-variance
