---
author: Charles O'Farrell
date: 2018/11/04 20:21:00
encoding: utf8
permalink: /2018/11/scala-source-builds-new-hope.html
categories: scala
title: Scala Source Builds - A New Hope
updated: 2018/11/04 20:21:00
layout: post
---

Having been on the JVM for all of my professional working life it took me a long
time to realise that using binary-based dependencies was not the only way to
depend on other projects. By this I mean that when you say the following:

```
"org.example" %% "foo" % "0.1.0"
```

This will download a jar from an http server that was published by a separate,
potentially unknown build.  One of the problems with this as your default means
of dependency management is that for _internal_ dependencies there is a
non-trivial cost in managing the relationship between multiple projects.

What happens if I want to fix a small bug? What happens if I want to share some
common logic across multiple projects?

Now you have to not only have to find that project, you have to go through a
whole separate process just to make a small change. And before you've even
"released" that change with a separate version number, you might want to test
that change on an upstream project. How easy is it to do a local release? Can
you then open that up for review and have, say, the tests to be visible to
reviewers?

What about fixing a bug in an open source library? How much effort is it to
fork, release and publish the changes to an internal repository?

None of this is insurmountable but it adds that extra layer of pain.  In my
experience is enough to change our behaviour. Rather than doing the "right
thing" and lifting a function/module in to a library we copy and paste it.

How do we lower the level of pain, even just a _fraction_?

## Source Dependencies

Source dependencies are where you depend on another
module/library and expect that your build process will be responsible to compile
it instead of someone else.

It's interesting that newer, hip languages like [Go] and [Rust] have gone back to
source dependencies as well. The JVM (I'm not sure about .NET) is one of the few
places where binary dependencies are the default.

[Go]: https://golang.org/doc/code.html#remote
[Rust]: https://golang.org/doc/code.html#remote

So what can we do given our current situation and tooling?

## Git Reference

SBT actually has a little known feature as part of
[multi-project](https://www.scala-sbt.org/1.x/docs/Multi-Project.html)
support that allows you to depend on another SBT project via a Git URL (with an
optional commit hash for stability).

```scala
lazy val root =
  (project in file("."))
    .dependsOn(RootProject(uri("ssh://git@github.com/foo/bar.git#78fb2722c598fc6d72ac47c069b6d004a34b6f5b")))
```

This solves the first problem of having to "publish" every change with a unique
version number. Updating the library is as simple as pushing to a branch and
updating the hash.

However, there is still a small barrier of having to actually _commit_ as well
as _push_, just to see the change in an upstream project. What if you want to
fix a bug that spans two projects?

Fortunately there is an easy solution that's sitting right in front of us.

## Git Submodules

Bear with me on this. Once upon a time I have
[argued](https://community.atlassian.com/t5/Questions/Stash-using-managing-multiple-repos-simultaneously/qaq-p/179386) heavily
[against](https://community.atlassian.com/t5/Bitbucket-questions/Stash-support-for-GIT-Submodules/qaq-p/269279)
their use. However, at my previous job I was exposed to using them in
anger and actually realised that my previous opinion didn't really hold up after
experiencing them first hand.

Before we talk about the issues, what does using a submodule look like in SBT?

```shell
> git submodule add ssh://git@github.com/foo/bar.git submodule/example
```

And then just point to the directory, SBT will know nothing about Git at this
point.

```scala
lazy val root =
  (project in file("."))
    .dependsOn(RootProject(file("submodule/example")))
```

## Git Submodule Workflow

Management of the version number is now done at the git level. Want to make a
fix?

```
> cd submodule/example
vi src/my/Example.scala
> cd ../..
> sbt compile
```

Rinse and repeat. That's it! The barrier to fixing or changing your library is
now almost zero. What about when you're done and want to "release":

```shell
> git status
  (use "git add <file>..." to update what will be committed) modified:
        submodule/example (modified content)
> cd submodule/example
> git add .
> git commit -m "Fix bug"
> git push origin feature/ACP-123-bug-fix

> cd ..
> git status
  Changes not staged for commit:
    (use "git add <file>..." to update what will be committed)
          modified:   submodule/example (new commits)
> git add .
> git commit -m "Updated example with bug fix"
> git push origin feature/ACP-123-bug-fix
```

The two projects may not be committed/pushed quite so quickly together. It may
be that the parent project requires more work to apply/test the bugfix/change.
What's nice is both branches (whenever they're ready) can have a PR opened, and
the builds will work without any intermediate releases. The benefits of source
builds!

## Git Submodules suck. No really.

So what's the problem? I need to be very upfront about the next part, which is
the tooling of git submodules is quite bad and clunky. Let me show you an
example of the most typical problem

```shell
> git status
Your branch is up to date with 'origin/develop'.
> git pull
> sbt compile
<insert compile error here>
# WTF?!?
> sbt compile
<insert compile error here>
```

What went wrong? The trap for young players is that
Git will not update the submodule as part of a pull.

```shell
> git status
Changes not staged for commit:
  (use "git add <file>..." to update what will be
committed)
  (use "git checkout -- <file>..." to discard changes in working
directory)

        modified:   submodule/example (new commits)
> git submodule update
Submodule path 'submodule/example': checked out
'9b08ccfc70319d1114647439e298b6ba7b54de73'
> git status

Your branch is up to date with 'origin/develop'.
```

I _guarantee_ if/when you use submodules you will run in to this problem at
least once. Eventually you learn to run `git status` reflexively, but you have
to experience the unexplained broken build and calling over the person who
merged the last branch a few times first before you learn.

### What's the catch?

Other than dealing with the quirks of the git submodule
tooling?

The biggest problem is that we're removing our inbuilt caching mechanism, each
machine has to now produce each project. Each build in CI in particular will
have to build each submodule project _every_ time. If/when we start to add more
submodules the build times will be impacted. The good news is that this doesn't
affect the developer workflow after the first build. When you updated a project
with submodules, given the target directory is persistent only the changes (if
any) will be built.

My gut feeling is we could easily implement our own custom
[SBT build loader](https://www.scala-sbt.org/1.x/docs/Build-Loaders.html) to
improve the caching if/when it becomes an issue.

## Further Reading

A blog that really started to change how I thought about build
system was the following.

- http://blog.lexspoon.org/2012/12/recursive-maven-considered-harmful.html
