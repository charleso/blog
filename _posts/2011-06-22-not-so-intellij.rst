---
author: Charles O'Farrell
date: 2011/06/22 20:33:00
encoding: utf8
permalink: /2011/05/not-so-intellij.html
categories: eclipse, intellij
title: Not-So-IntellJ
updated: 2011/06/22 20:33:00
draft: true

---

Trying new things is an essential part of any software developer's day.
However, will the day come in every developer's life when the cost of
changing the habits of a lifetime, or at least part of one, is greater
than the cost of sticking with the devil you know?

I've been a Java developer for quite a few years. At University we were shown CodeWarrior_, 
and looking back now all I can remember is a glorified syntax highligher.
When I started at my first job the IDE of choice was JDeveloper_ which wasn't much better.
At some stage shortly after I started a team member introduced us to Eclipse. 

.. _CodeWarrior: http://en.wikipedia.org/wiki/CodeWarrior
.. _JDeveloper: http://en.wikipedia.org/wiki/JDeveloper

Wow.

At the time it blew my mind. Being able to navigate around methods at the click of button, 
find method references, *refactor*. 
Sure, it's stuff we take for granted now, but at the time it totally enhanced the experience of working in Java.
Finally all those relationships between classes was something you could touch and play with. 
Where the hell had this been earlier and how the hell had we lived without it?!?

Fast forward to 2011 and I've been using Eclipse ever since. Almost every day of my working life.
It's fair to say I know it like the back of my hand.
Every shortcut; every nuance. However, you could also say I've become entrenched.

One of the interesting things about working at my current company is observing and comparing the mindset of our older COBOL developers.
Many of them have been using Emacs for 10+ years. They know the ins-and-outs, the custom shortcuts, the quirks. (How about saying: "They know it like the backs of their hands. Every shortcut; every nuance."

Sound familiar?

XXX We've been (slowly) introducing Eclipse as the new environment for future development.
I don't think I need to explain how well this news has been taken. XXX 
Now I'm drawing a long bow at this point, but the thought that I'm doomed to a similar fate
has certainly crossed my mind more than once recently.

[George: What about: "We've been (slowly) introducing Eclipse as the new environment for future development. As you might imagine, it has not been completely well received by the COBOL developers. But that's hardly surprising is it? It's new. And different. And it has certainly crossed my mind that if we were changing to Emacs, I would have a similar reaction to them. The difficulty of learning a completely new way of doing something totally familiar is, I suspect, a human condition.]

For some time I heard nothing but good_ things about IntelliJ_ IDEA,
and I've been meaning to make a switch. Every now-and-then I would download the latest copy, fire it up
and see if I could be awed once again, much like my first Eclipse experience. Being slightly disappointed,
and a little frustrated in the differences, I close it down again. *Perhaps when I have more time* I say to myself.
And of course, that time never comes. Why bother, when Eclipse does everything I need?

.. _good: http://www.aldana-online.de/2010/12/12/intellij-idea-rocks-revisted-for-10/
.. _IntelliJ: http://www.jetbrains.com/idea/

With the advent of Scala I may now found a compelling reason to try one last time.
After a brief trial, and some research_, I found the Eclipse plugin_ to be the lesser of the two. (Question: lesser of 2 what?)
I should note that at the time of writing this was version 2.0.0-beta5, and I strongly suspect 
that given that `Martin Odersky`_ has personally_ put his support 
behind the endeavour that this situation may be reversed in a few months. Who knows?

.. _plugin: http://www.scala-ide.org/
.. _Martin Odersky: http://en.wikipedia.org/wiki/Martin_Odersky
.. _personally: http://skillsmatter.com/podcast/scala/the-new-scala-eclipse-plug-in/js-2088
.. _research: http://stackoverflow.com/questions/419207/which-is-the-best-ide-for-scala-development

I decided to go cold-turkey and live within IntelliJ for the next couple of weeks until, well, I don't know.
Until I get sick of it, or I finally see the light I suppose.

Probably the biggest problem that I've come across so far is the lack of a feature complete Ivy plugin.
The Eclipse plugin, IvyDE_, is really quite impressive. For IntelliJ there is a number_ of_ options_; none
of them quite good enough to give a seamless experience. For my money IvyIDEA_ is the most mature,
but sadly it is no longer being maintained as of this year. Jetbrains has indicated_ that they might be
considering introducing native support, but this isn't the first of such claims_. Actually I suspect
it will happen sooner rather than later, but of course that doesn't help us *right now*. 
Just for the sake of completeness the biggest problem at the moment_ is the lack of transitive dependencies
in projects, although this can be fixed manually.

.. _IvyDE: http://ant.apache.org/ivy/ivyde/
.. _number: http://plugins.intellij.net/plugin/?id=141
.. _of: http://plugins.intellij.net/plugin/?id=2267
.. _options: http://plugins.intellij.net/plugin/?id=3612
.. _IvyIDEA: http://code.google.com/p/ivyidea/
.. _moment: http://code.google.com/p/ivyidea/issues/detail?id=36
.. _indicated: http://blogs.jetbrains.com/idea/2011/02/announcing-intellij-idea-105-with-full-java-7-support/#comment-170861
.. _claims: http://blogs.jetbrains.com/idea/2010/05/maven-dependencies-diagram/#comment-136123

Another problem is that IntelliJ has more difficulty with *unnaturally* large jars (Question: more difficulty than what?). And when I say 'unnatural',
I really do mean it. For example we have an unusually large jar which is about 222MB, containing roughly 19000 classes.
I'm not sure there are many people who can claim to have such a beast, nor would many want to.
I'd rather not delve into why on *God's Earth* we managed to concoct such a monstrosity, suffice to say we don't 
have much choice. Actually, I hope to get a chance to explain why in a future post. 
For now the issue is that while IntelliJ is indexing, which happens on *every* startup, you might as well go and get a coffee, 
because there is very little you can do while it happens. For that one jar it takes roughly an hour. Yes, an hour.
I'm glad I'm not trying this with IDEA 9, because apparently_ it was worse.
Eclipse, while also struggling, at least lets you go about your business. 
For example you can't even create classes in IntelliJ while it's indexing.
To avoid this I've, ahem, 'tweaked' com.intellij.openapi.project.CacheUpdateSession in idea.jar to bypass
certain jars being indexed. It's not perfect, but it means I can restart IntelliJ without losing an hour.

.. _apparently: http://blogs.jetbrains.com/idea/2010/12/intellij-idea-10-rc-3-indexing-speed-improvements/

In many ways the hardest thing to deal with on a day-to-day basis is the complete remapping of keyboard shortcuts.
After so many years of doing things with Eclipse it's hard to re-train my brain/finger mapping.
Now, there is a handy built-in Eclipse keymap, which would save me some of that work. 
However, I'm a *firm* believer in defaults. I've found that you can be much more productive if you reduce 
your dependency on a personalised configuration. For example I try to avoid creating Git aliases, which
helps when I switch machines--for example, to help other people.

Now I'm sure this next part is inherently biased given my background, but I'm going to put it out there anyway - 
I think *some* of the shortcuts in IntelliJ are poorly chosen, *especially* for a poor Linux user like myself.
For example:

- Closing a tab in *most* applications, like Eclipse/Firefox/etc, is Ctrl+W.
  In IntelliJ it's Ctrl+F4. Not only is that a different,
  I can't see any easy way do that without lifting my right hand across or
  completely moving my left so my thumb is on ctrl.
- Ctrl+Alt+Left/Right - Back/Forward. Also switch virtual desktops on Ubuntu.
- Ctrl+Alt+L - Format. Also logout on Ubuntu.
- Alt+F8 - Evalutate expression. Also move window on Ubuntu.
- Alt+F9 - Run to line. Also minimize windows on Ubuntu.

Do I remap the keys in IntelliJ? Or Ubuntu? For now I've done the latter but I'm not happy about it.
To be fair, Eclipse has similar clashes, but not quite so many. It's those damn 'F' keys!
I suppose it would be nice if our IDEs could standardise on a single keymap,
but that will never happen this late in the game.
I *do* like Ctrl+Shit+A, which is a general-purpose menu, much like the Ctrl+3 button in Eclipse.
Even better it displays the shortcut next to each option.

I'm still finding my way with IntelliJ, but I'm already finding some nice surprises.
One of the initial things that I like about it already is that
you can nominate folder as being 'test'. This helps when navigating the call hierarchy of the method. 
Quite often you want to exclude calls made by test methods, as they only serve to get in the way.

Another feature I love is the Spring facet. IntelliJ automagically (Question: did you mean to say 'automagically?) found my Spring files and annotated
methods that had been aspected. (Question: aspected?) Eclipse has a equivalent plugin, but I have never bothered to install it before.
I suppose that's one of the arguably nice things about IntelliJ - that it works out-of-the-box with the *stuff that matters*.
In some ways this reminds my of one of the strongly debated differences between Git and Mercurial,
the former has everything-but-the-kitchen-sink, the latter can be enhanced via plugins. 
There are advantages and disadvantages to both; which you like largely depends on personal preference.

Finally, I have noticed that general navigating around Java classes is *much* snappier,
such as following links, viewing call hierarchies etc. I sometimes avoid doing simple refactors in Eclipse
because it's actually faster to do it manually.
This is probably due the deeper/slower indexing that IntelliJ does on startup, as mentioned earlier.
Although why Eclipse can't do the same thing is a mystery to me...

If anyone has a similar experience with IntelliJ, working with defaults or general feedback please don't hesitate to comment. 
I'm curious how other people have tackled XXX
