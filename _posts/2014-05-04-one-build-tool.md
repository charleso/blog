---
author: Charles O'Farrell
date: 2014/05/04
encoding: utf8
categories: build
title: One Tool To Build Them All
layout: post
---

*This post was originally hosted separately on my
[bitbucket](https://bitbucket.org/cofarrell/one-build-tool) account*

**Update from 2018**: I don't think my younger self got this right, I wouldn't
mind writing a following on piece at some point. Please take this post with
a grain of salt (or two).

![One Ring](/assets/one-ring.jpg)


> Build tools should use a build cache, emphasis on the cache, for propagating results from one component to another. A cache is an abstraction that allows computing a function more quickly based on partial results computed in the past. The function, in this case, is for turning source code into a binary.
> A cache does nothing except speed things up. You could remove a cache entirely and the surrounding system would work the same, just more slowly. A cache has no side effects, either. No matter what you've done with a cache in the past, a given query to the cache will give back the same value to the same query in the future.

The above quote was taken from Lex Spoon's amazing
[Recursive Maven Considered Harmful](http://blog.lexspoon.org/2012/12/recursive-maven-considered-harmful.html).
I stumbled across Lex's post in the equally good
[In Quest of the Ultimate Build Tool](http://blog.ltgt.net/in-quest-of-the-ultimate-build-tool/).

Over the past couple of months I've begun my own quest, to seek out new build
tools and to boldly shave a yak no developer has shaved before.

- [Part 1 - Everyone is cheating](#clearcase)
- [Part 2 - Ultimate Build Tool](#ultimate-build-tool)
- [Part 3 - Nix](#nix)

Beware: This series doesn't contain any answers. I wish it did.

## Clearcase

In a past life I had the misfortune to be stuck working with
[Clearcase](http://en.wikipedia.org/wiki/IBM_Rational_ClearCase).
I hated it so much that I even
[wrote my own bridge to Git](https://github.com/charleso/git-cc).

Despite it's many flaws it also has some interesting features that we
currently lack in this new Git world.

A large part of Clearcase is the concept of "dynamic views", where a custom
filesystem is used to provide a "view" of the entire code base, but files are
only downloaded on demand.

This can be combined with
[Clearmake](http://publib.boulder.ibm.com/infocenter/cchelp/v7r0m0/topic/com.ibm.rational.clearcase.cc_ref.doc/topics/clearmake.htm),
which caches binary artifacts derived from input source files, which can be
winked in" to another view with those identical inputs.

A few quick observations.

1. The problem with Clearcase is that it does everything per-file. SVN and Git
have shown us the power of atomic commits, but I think the wheel is
turning and we need to cache build results based on "modules", rather than
"files". But it's the same shit, just at a different level.

2. Custom file systems make clever tricks like Clearmake very easy, you
can automatically detect every input without needing explicit declaration.
However custom filesystems are complex, and I suspect the future lies elsewhere.

This actually sounds a lot like
[Google's file system](http://google-engtools.blogspot.com.au/2011/06/build-in-cloud-accessing-source-code.html)

## Look Ma, No Pants

Two of the most interesting build systems that are emerging at the moment are
[Buck](http://facebook.github.io/buck) and [Pants](http://pantsbuild.github.io/),
both based on
[Google's Blaze](http://google-engtools.blogspot.com.au/2011/08/build-in-cloud-how-build-system-works.html).

However, I would argue that both have a fundamental flaw that I suspect will
make them impossible for handling modules at different versions.
And that is that they assume everything is kept in a single folder structure.
A temporary work around would be to use Git Submodules. But consider Buck build
target's, which are always absolute. What happens if you have:

    Project A:
        - BUILD
        - /lib/foo
        - Project B (Git submodule)
            - BUILD
                - //lib/foo
            - /lib/foo

At least at the moment `//lib/foo` will mean something different depending on
where Buck decides is the "root".

Buck and Pants are just not designed for building sub-components of a system.
How would you extract a submodule with it's own release cycle (eg. open
sourcing a library)? The answer, I suspect, is you have to step outside the warm
comfort of your specialised build tool.

## Facebook

Facebook recently announced how they were using Mercurial to
[scale their codebase](https://code.facebook.com/posts/218678814984400/scaling-mercurial-at-facebook/
).

Some of the advantages of this approach.

1. Refactoring is easy - everything is technically in the same codebase
2. Nothing to "release"

Not surprisingly I agree with [the critics](https://news.ycombinator.com/item?id=7020143)
of this approach that they should be looking to modularise rather than lump
everything together.

## Cheating

As we've seen companies like Facebook and Google can solve their build
problems by "cheating".
And by cheating I mean they are making a reasonable optimization based on 
reducing variables, such as restricting everything to a single codebase.
To be clear I'm not criticising this approach, but I don't believe that is
reusable/useful in the general case, which is all I really care about.

To take an example of why this wouldn't work, let me talk about Atlassian.
We have a number of different products such as JIRA, Confluence and Stash.
Obviously we want to share common libraries, but each product has a different
release cycle. In a single codebase both would have to _always_ build against
the latest version of libraries (which isn't necessarily a bad thing, but that's
a topic for another day). Introducing a new feature in the library for one
product may break another accidentally. As hinted above I believe this is the
same problem faced at Google/Facebook if they decide to exact a library for
open sourcing.


## Ultimate Build Tool

To help expand on what I'm envisaging, let's step through through a typical day
of the life of a developer using UBT.

08:30 -
Bob starts work by pulling from Project A to get the latest. He runs a build,
which doesn't take very long because the build machine ran last night and he
downloads only new artifacts. That's probably a good thing because his team is
using Scala and it's slow at compiling.

09:00 -
As Bob works on a new feature he decides he needs to update a common library
that his company have open sourced. He runs `ubt checkout libB` which clones the
source of `libB` into his project and he adds that to his IDE.
Running `ubt build` does nothing yet because the files in `libB` haven't changed
yet.

10:00 -
Bob has finished work on his feature and adding a new method to libB. He runs
`ubt checkout -b feature/X`, `ubt commit -m "Feature X"` and `ubt push` which
commits the changes to the two different repositories, pushes the change in
project A to the internal Git server, and libB to Github. He then creates a
review in both systems.

10:01 -
The build server, which is configured for Project A, starts building detects
that libB has been updated and clones/builds this module first, and then builds
Project A.

11:00 -
The changes for Project A are accepted and then merged even though the PR for
libA is still open. When the build runs again, nothing needs to happen because
the filesystem is identical to the previous build.

12:00 -
Bob's team decides they want to do a release, and click the "release" button in
the build server, which does nothing but add a tag to the latest commit in
Project A and marks the artifact to keep.

12:05 -
Alice has just pulled the latest and run a build, which also does nothing but
download the new artifacts for both Project A and libB as they have already been
built.

13:00 -
The artifact server runs it's daily GC, cleaning up the artifacts from the
previous day, but leaving any artifacts that have been marked as "release"
(including all the dependencies).

Please excuse the farcical example, but I hope it illustrates what I think we
should be striving for. For developers at Facebook/Google I suspect some of this
is largely a reality, but what about the rest of us?

In particular I want to point out a few things that are missing from the
previously mentioned build tools.

- No need for a manual "release" when depending on another repository
- A "release" is just a tagged commit, no bullshit `mvn release` required
- While there are multiple Git repositories, it acts like a single filesystem,
  but the advantage being that dependencies can be versioned independently at
  the module level, declared only as commit hashes.

So when can you start using UBT?


## Nix

[Nix](http://nixos.org/nix/) is a "purely functional package manager" that was
[conceived by Eelco Dolstra way back in 2003](https://nixos.org/docs/papers.html).
Nix captures _every_ input into a source build, which ensures they can be
recreated. In addition it supports downloading build artifacts to be used in
place of a source build if (and only if) the inputs are identical.

One of the things that caught my attention was Nix's companion build server
[Hydra](https://nixos.org/hydra/).
It can build a single Nix expression, but recognises the dependencies between 
builds which re-uses components. Here is an example of a build of common
dependency of a project (note the "cached from" link).

![hydra screenshot with cache](https://bytebucket.org/cofarrell/one-build-tool/raw/master/images/hydra1.png)

Hydra has the concept of a "release", which just promotes previous builds.

Finally, Nix has something called a "channel", which is a list of expressions
and their binary output. 
You can subscribe to a channel, and Nix will automatically
download binary artifacts if the local expression matches.
Hydra conveniently publishes a channel with the latest artifacts of each project.
Unreferenced artifacts can be garbage collected by running `nix-store --gc`.

This only touches on a few of features of Nix, but these are the ones that align
with my "wish list" of UBT features.

## Friends with benefits

An interesting benefit that falls out of Nix is that it understands _how_ to
build things. This is not necessary surprising if you think about source builds.

For example it's easy to think about have a Java-only build or \<insert
favourite  language here\>, but what happens if you introduce another language,
such as Javascript.
What happens if you want to compress the files before releasing or compile from
Coffeescript?
You _could_ write a specilised Maven plugin that has to be written in Java.
What happens if you want to make use of `node` or some non-java binary.
How do you ensure developers have their machine configured correctly?

To build with _any_ command in Nix, even simple commands like `mv` or `cp`, need
to be declared as inputs.
As part of the input to your build you must provide the recipe for these,
just like any of your other dependencies. When someone builds your script it
will first need to resolve those inputs, which may potentially result in a build
or download of `mv`, and so on. The same is true for `javac` or any other
compiler, why given them special treatment?

It's turtles all the way down.

### So what's the catch?

To use Nix as UBT comes with a few gotchas.

#### Recursive Builds

Nix currently doesn't support recursive builds. It requires that the entire
"expression" is on the local filesystem. This would require that _every_
dependency that is built with Nix for a given build would need to cloned,
regardless of whether you manage to download a binary artifact.
For someone just starting on a new project this could be incredibly cumbersome.

As of only a few months ago Shea Levy has
[opened a PR](https://github.com/NixOS/nix/pull/213)
that looks to rectify that.
I also had an enlightening
[discussion with Shea on IRC](http://nixos.org/irc/logs/log.20140427).

#### Full rebuilds

This one is a little trickier.

Let's take a very simple Java Nix project.

```
{ pkgs ? import <nixpkgs> {} }:

pkgs.java {
    dir = ./.;
    name = "helloworld";
}
```

And now it's corresponding "derivation".
This is what Nix resolves everything to, you can think of it like the "assembly
language" recipe of Nix.

```
Derive([("out","/nix/store/w0697grv83xykir3fmngwaly7mc5vmjh-helloworld","","")],[("/nix/store/6dmxczi276k08nzfzddhh3fk5wkkmwgb-bash-4.2-p45.drv",["out"]),("/nix/store/jmsakyghcbdqpv42a4rklazsnwv1asf4-openjdk6-b16-24_apr_2009-r1.drv",["out"]),("/nix/store/qvc02f9d05jgad3zg8d4w5dhbxyb6y75-stdenv.drv",["out"]),("/nix/store/yj6svnmlydgk04hysh6gkw0mvqf6isbs-bcprov-jdk15on-148.drv",["out"])],["/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh","/nix/store/r5s1hacbpdkgsppj8chgj2nrajgs0cd3-src"],"x86_64-darwin","/nix/store/85h1r887x7raf97l1invbm9zg1c1sfxr-bash-4.2-p45/bin/sh",["-e","/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh"],[("buildInputs",""),("buildPhase","javac -d . $(find $src -name \\*.java)\njar cfv $name.jar $(find . -name \\*.class)\n"),("builder","/nix/store/85h1r887x7raf97l1invbm9zg1c1sfxr-bash-4.2-p45/bin/sh"),("installPhase","mkdir -p $out/share/java\ncp $name.jar $out/share/java\n"),("name","helloworld"),("nativeBuildInputs","/nix/store/jfdm85gv2nymw7wryhfssw3hgpzaxnwg-openjdk6-b16-24_apr_2009-r1 /nix/store/k2c9pr2zymsa2zikk0ypsjd9risnyz4h-test /nix/store/i3bf5l4xabncljnx6gnmp3a430s2np44-bcprov-jdk15on-148"),("out","/nix/store/w0697grv83xykir3fmngwaly7mc5vmjh-helloworld"),("propagatedBuildInputs",""),("propagatedNativeBuildInputs",""),("src","/nix/store/r5s1hacbpdkgsppj8chgj2nrajgs0cd3-src"),("stdenv","/nix/store/kamf5pgp6fx5gmhk86csg8w43l1mcdln-stdenv"),("system","x86_64-darwin"),("userHook","")])
```

Because Nix is tracking _every_ input, you might be able to see that
for my build I would first need `bash-4.2-p45` and `openjdk6-b16`.
For this binary artifact to be shared (via a channel) to other users, they would
also need those _exact_ dependencies.
Even the slightest change in Nix environment would result in a cascading build
of every library.

At least coming from my cosy Java world this seems excessive. Compiling an
artifact with Java 6.x will produce an artifact that is compatible with any
subsequent Java version and any OS, give or take methods that have been
removed from the core library.

I suspect this is an inevitable trade-off between fully reproducible builds and
convenience/speed. Once you start messing with what it means to be a dependency
you end up with builds that aren't always reproducible because you made an
assumption that was true at the time, but latest proved to be false.

## Ixnay on the eamdray

I was vaguely hoping that my investigations into Nix would have a more immediate
and practical outcome.
It certainly solves the source build problem in a powerful and elegant way,
but perhaps a little _too_ well.
Is there a middle ground? Can I have my cake and eat it too?
