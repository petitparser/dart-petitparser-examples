PetitParser
===========

Grammars for programming languages are traditionally specified statically. They are hard to compose and reuse due to ambiguities that inevitably arise. PetitParser combines ideas from scannerless parsing, parser combinators, parsing expression grammars and packrat parsers to model grammars and parsers as objects that can be reconfigured dynamically.

PetitParser was originally implemented in [Smalltalk](http://scg.unibe.ch/research/helvetia/petitparser). Later on, as a mean to learn these langauges, I reimplemented PetitParser in [Java](https://github.com/renggli/PetitParserJava) and [Dart](https://github.com/renggli/PetitParserDart). The implementations are very similar in their API and the supported features. If possible I tried to adopt common practices of the target language.

Tasks
-----

* Get rid of the global functions creating `PredicateParser` instances.
* Investigate if working on character codes than on sub-strings would improve performance.
* Use constructor initializiers in `PredicateParser` as soon as Dart allows functions in constructor initializers.
* Use #import('dart:unittest') as soon as Dart officially blesses the testing framework.

Need to find workarounds for the following problems in Reflection.dart:

* Copying objects is not easily possible (http://code.google.com/p/dart/issues/detail?id=3367)
* hashCode() based on the object identity is not available (http://code.google.com/p/dart/issues/detail?id=3369)