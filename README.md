hakawai-textview
================

A subclass of ``UITextView`` providing extended functionality and support for 'plug-ins'. Hakawai ships with the 'Mentions' plug-in, which provides a powerful and flexible way to easily add social-media-esque 'mentions'-style annotation support to your iOS application.


Features
--------

- A convenient drop-in replacement for ``UITextView`` instances, including those in Storyboards or XIBs.
- Easily add, remove, and transform the text view's plain and attributed text using a set of powerful block-based APIs.
- Work with attribute formatting and easily register or unregister custom attributes with enhanced attribute APIs.
- Easily add, remove, and manage accessory views, UI elements that can be added to or removed from the text view for additional functionality.
- Lock the current line of text to the top or the bottom of the text view using single-line viewport mode.
- Programmatically dismiss autocorrect suggestions, and temporarily override the autocorrect, autocorrection, and spell checking modes.
- Extend functionality by registering or unregistering plug-ins.
- Custom 'rounded rect background' attribute, and a custom layout manager allowing additional attributes to be defined.
- The fact that this text view implements a custom layout manager and text container fixes several ``UITextView`` bugs by default.
- *EXPERIMENTAL* - Easily monitor user changes to the text view's contents using the optional Abstraction Layer; two-stage insertion for Chinese and Japanese keyboards is also properly handled. The Abstraction Layer is built into the text view; it can also be pulled out and used independently if you desire.


Get Started
-----------

Hakawai makes extensive use of TextKit, and requires iOS 7.1 or later. (Unfortunately, there are severe TextKit bugs in 7.0 that break many of the features offered by the library.)

If you are using CocoaPods, just add ``pod 'Hakawai'`` to your Podfile. Otherwise, check out the project and copy the source files into your own project.

Hakawai uses class extensions, and as a result you should add the -ObjC linker flag to your project settings if it's not there already. CocoaPods will automatically configure this for you if it's not already set.

The primary Hakawai entity is the ``HKWTextView``, which takes the place of a vanilla ``UITextView``. Use it the same way as you would a ``UITextView``, with one important exception: **never** set the ``HKWTextView``'s ``delegate`` property. Instead, if you need the functionality of the ``UITextViewDelegate``, set the ``externalDelegate`` or ``simpleDelegate`` properties instead.

Hakawai's functionality is divided up into three main categories:

- ``HKWTextView+TextTransformation`` contains methods for working with and altering text and attributes within the text view
- ``HKWTextView+Extras`` contains miscellaneous utilities
- ``HKWTextView+Plugins`` contains an API intended for consumption by plug-ins; you may use these features directly as well, but doing so may or may not cause conflicts with any active plug-ins


### Sample App

The ``HakawaiDemo`` sample app demonstrates some of Hakawai's features.

The first tab contains a simple text entry field with buttons to reverse or perform a [ROT13](http://en.wikipedia.org/wiki/ROT13) transformation on the selected text.

The second tab demonstrates control flow plug-ins and the Abstraction Layer, and contains a 'console' which will display the user's actions as they type in or delete text.

The third tab demonstrates the mentions plug-in. You can type in ``@`` or ``+`` to see a list of entities (for demonstration's sake, the [25 earliest Turing Award winners](http://amturing.acm.org/byyear.cfm)) that you can select. You can also type in three characters of the name to bring up the chooser.


Plug-ins
--------

Plugins are defined in the podspec file as subspecs, so you can pick and choose which plug-ins you want to use (as long as you include the Core subspec). If you are not using CocoaPods, each plug-in is located in a separate group in Xcode, and each plug-in's group can be deleted wholesale without compromising the functionality of the core library.

Hakawai supports two types of plug-ins. 'Simple' and 'control flow' plug-ins both receive references to the parent ``HKWTextView``, but control flow plug-ins can also implement additional delegate methods, allowing them to respond to changes in the text view's state. Plug-ins also have access to all the APIs of the core ``HKWTextView``.

There are two types of control flow plug-ins. *Direct control flow plug-ins* receive ``UITextViewDelegate`` methods in order to monitor the state of the text view and respond to user actions. *Abstraction layer control flow plug-ins* receive ``HKWAbstractionLayerDelegate`` methods instead. Note that only at most one of the two types of control flow plug-ins may be registered to the text view at a time.

Multiple simple plug-ins may be registered at once, but only one control flow plug-in can be registered at a time. Plug-ins can also be unregistered at any time.


Mentions Plug-in
----------------

Hakawai/Mentions is a plugin that allows annotations to be created within a ``HKWTextView``. Annotations are portions of text which refer to specific entities, treated as a monolithic unit, and can be styled differently from the rest of the text. Examples of annotations are the 'mentions' feature supported by many popular social media applications.

To see Mentions in action, check out the demo app. Or download the LinkedIn mobile app from the App Store, log in with your LinkedIn account, and mention a connection or company in a comment!


### Features

- Easy to use - just implement a method to return results for a query string, and a method to return a cell for displaying a result
- Support for implicit annotations (which are triggered after a customizable number of characters are typed)
- Support for explicit annotations (which are triggered once one of any number of special characters are typed)
- State machine-based logic makes changing or extending behavior less cumbersome
- Query results can be returned synchronously or asynchronously
- Multiple sets of results can be returned for a single query
- Automatic rate limiting of queries
- Annotations 'light up' if the user moves the selection cursor into them, or taps the backspace key with the cursor immediately following an annotation.
- The plug-in offers the option to intelligently trim annotations; for example, truncating a full name into just a first name
- Almost every aspect can be customized: styling of annotation in the highlighted and un-highlighted states, chooser view, results cells, etc
- Annotations state is kept properly consistent even if user cuts and pastes text
- Annotations work properly with autocapitalization and autocorrection


### Get Started

1. Create a helper class that implements the three required methods in ``HKWMentionsDelegate``
2. Create an instance of ``HKWTextView``
3. Create an instance of ``HKWMentionsPlugin`` using one of the factory methods
4. Set the mention plug-in's ``delegate`` property to an instance of your helper class
5. Call ``registerControlFlowPlugin:`` on the text view instance to register the plug-in

See the documentation comments for more information on the relevant classes and methods.


### Delegate Methods

There are three required delegate methods in ``HKWMentionsDelegate``:

- ``asyncRetrieveEntitiesForKeyString:searchType:controlCharacter:completion:`` is how the plug-in asks your app to translate some search string into results.
  - ``keyString`` is a search string containing the text that the user wants to use to create the annotation
  - ``type`` is an enum describing whether the annotation is an *explicit* annotation (user typed a control character) or an *implicit* annotation (user typed in some number of characters). Your app may wish to return different results for each type of annotation.
  - ``controlCharacter`` is the character the user typed to start an explicit annotation; it should be ignored otherwise
  - ``completionBlock`` is a block that your app should call once results are available. It takes an array containing result objects that conform to ``HKWMentionsEntityProtocol``, as well as a boolean indicating whether or not this set of results is the final set of results for the given query. If YES, calling the block again will have no effect. If the results array is empty or ``nil``, the plug-in will ignore the boolean and ignore any further invocations of the block. Otherwise, the block may be called repeatedly in order to append results. Your app does *not* need to worry about whether the search string is still valid when the block is called; the plug-in handles all of this automatically.
- ``cellForMentionsEntity:withMatchString:tableView:`` is how the plug-in asks your app for a table view cell in which to display a result.
  - ``entity`` is the entity corresponding to the cell; you returned it earlier as part of the previously described API method
  - ``matchString`` is the string containing the text the user is currently using to create the annotation; it may be useful for formatting the cell
  - ``tableView`` is a reference to the table view requesting the cell
- ``heightForCellForMentionsEntity:tableView:`` is how the plug-in asks your app for the height of the table view cell returned by the previous API method.


### Positioning

There are several positioning modes, all of which are described by the ``HKWMentionsChooserPositionMode`` enum. One of these modes must be passed in when the mentions plug-in is created. A comprehensive description of each mode can be found in the ``HKWMentionsPlugin.h`` header file.

The ``EnclosedTop`` and ``EnclosedBottom`` modes automatically position the chooser UI completely within the text view, leaving a gap at the top or the bottom respectively for user input.

The 'custom' modes allow the chooser view to be positioned arbitrarily relative to other UI elements on the current screen. The custom modes rely upon a block which you provide, called when the chooser view is first added to the view hierarchy. This block allows you to set up Auto Layout constraints as you see fit. In particular, call the ``setChooserTopLevelView:attachmentBlock:`` method before the chooser UI appears. The block takes one argument, which is a ``UIView`` representing the chooser view.


### Behavior

A brief discussion of the state machine architecture and its implications follows.

The plug-in manages an overall state machine. This state machine in turn manages two subsidiary state machines that govern the plug-in's behavior:

- The *start detection state machine* is responsible for monitoring the user's actions when the annotation creation process is inactive, and determining when to begin the creation process
- The *creation state machine* is responsible for supervising the annotation creation process, querying the host app, presenting the UI, and completing or canceling the creation process as necessary

If the user is not creating an annotation, the start detection state machine monitors the number of non-whitespace, non-newline characters typed since the previous whitespace or newline, and starts the search process if enough consecutive characters are typed. The search buffer is reset every time a whitespace or newline is typed. The search process is also started immediately if a control character is typed.

When the plug-in is in the annotation creation process, inserting or deleting characters will cause the plug-in to query its delegate for an updated set of search results. If the user deletes all characters, the creation process is canceled; however, even if the annotation was implicitly started, the user may delete all but the last character without canceling the process. For example, if the implicit start threshold is five characters, the user can still delete characters from (e.g.) "Peter" to search on "Pete", "Pet", "Pe", or "P".

If the user enters or deletes characters to the point where there are no results, and then types a whitespace or newline character, the creation process is immediately canceled. If the user taps within the single line viewport, moves the cursor, or tries to cut or paste test, the creation process is canceled.

If an annotation is created, the creation process is canceled, or the cursor is moved to a location where the preceding character is neither a whitespace or a newline, the plug-in is considered to be *stalled*. The annotation creation process will not be allowed to start again until the user types a whitespace or newline character, or moves the cursor to precede a whitespace or newline character (or the very beginning of the text).


Testing
-------

Hakawai includes an almost-comprehensive unit test suite for the main text view powered by the [Specta and Expecta libraries](https://github.com/specta/specta). We hope to have test coverage for the abstraction layer and mentions plug-in in the future, although unit tests are probably not sufficient for testing these components. 


Contributions
-------------

Bug reports, feature requests, pull requests, comments, criticism, and honest feedback are all welcome. Please email austinzheng (at) gmail (dot) com.

Plans for this library include:

- Verifying proper functionality and integration of Abstraction Layer
- Abstraction Layer support for Korean text input
- Automated testing


Etymology
---------

According to Wikipedia, "In Māori mythology, [...] Hakawai is a monstrous bird that ate people".


Copyright & License
-------------------

Hakawai © 2014 LinkedIn Corp. Licensed under the terms of the Apache License, Version 2.0.
