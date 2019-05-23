[![Build Status](https://dev.azure.com/lnkd-oss/Hakawai/_apis/build/status/linkedin.Hakawai?branchName=master)](https://dev.azure.com/lnkd-oss/Hakawai/_build/latest?definitionId=3&branchName=master)

# Hakawai

A subclass of `UITextView` providing extended functionality and support for 'plugins'. Hakawai ships with the `Mentions` plug-in, which provides a powerful and flexible way to easily add social-media-esque @mentions-style annotation support to your iOS app.

*For a higher-level overview, check out our [blog post](http://engineering.linkedin.com/ios/introducing-hakawai-powerful-mentions-enabled-text-view-ios) at the LinkedIn engineering blog.*


## :sparkles: Features

- A convenient **drop-in replacement** for ``UITextView`` instances
  - Includes Storyboards and XIBs
- Easily modify **add, remove, and transform** the text view's plain and attributed text using a set of powerful block-based APIs
- Work with attribute formatting and easily register or unregister **custom attributes** with enhanced attribute APIs
- Easily add, remove, and manage **accessory views**
  - These UI elements can be added/removed from the text view for additional functionality
- **Lock the current line of text** to the top or the bottom of the text view using single-line viewport mode
- Programmatically **dismiss autocorrect suggestions**, and temporarily override the autocorrect, autocorrection, and spell checking modes
- Solve several `UITextView` text layout bugs as Hakawai implements a **custom layout manager and text container**
- **Extend functionality** by registering or unregistering plugins
- *EXPERIMENTAL* - Easily **monitor user changes** to the text view's contents using the optional Abstraction Layer
    - Two-stage insertion for Chinese and Japanese keyboards is also properly handled
    - Abstraction Layer is built into the text view
    - Can also be pulled out and used independently if you desire

## :wrench: Getting Started

*For more detailed documentation, check out the [wiki](https://github.com/linkedin/Hakawai/wiki).*

### Requirements

- **iOS 7.1:** Hakawai supports iOS 7.1 or later, as it makes extensive use of TextKit. Severe TextKit bugs in iOS 7.0 break many of the features offered by the library. At your own risk, you may try using Hakawai with iOS 7.0 (this may be a viable option if you only want to use the text transformers).

- **Linker flags:** Hakawai uses class extensions, and as a result you should add the `-ObjC` linker flag to your project settings if it's not there already. CocoaPods will automatically configure this for you if it's not already set.

### Integrating Hakawai

- **Cocoapods:** just add `pod 'Hakawai'` to your Podfile and install as normal
- **Manually:** check out the project and copy the source files into your own project

### Functionality

The primary Hakawai entity is the `HKWTextView`. It is a direct replacement of a vanilla `UITextView`, and may be used the same way as a `UITextView` with one important exception. **Never** set the `HKWTextView`'s `delegate` property. If you need the functionality of the `UITextViewDelegate`, set the `externalDelegate` or `simpleDelegate` properties instead. Those delegates combined should cover all use cases for which you would otherwise use `delegate`.

Hakawai's functionality is divided up into three main categories:

1. **`HKWTextView+TextTransformation`:** methods for working with and altering text and attributes within the text view
1. **`HKWTextView+Extras`:** miscellaneous utilities
1. **`HKWTextView+Plugins`:** an API intended for consumption by plugins
   - You may use these features directly as well, but doing so may or may not cause conflicts with any active plugins

### Sample App

The `HakawaiDemo` sample app demonstrates some of Hakawai's features. Get it by using CocoaPods' `try` feature: `pod try Hakawai`, or by manually checking out the repository and running the `HakawaiDemo` scheme. Here's what's included:

1. **First tab:** a simple text entry field with buttons to reverse or perform a [ROT13](http://en.wikipedia.org/wiki/ROT13) transformation on the selected text

1. **Second tab:** demonstrates control flow plugins and the Abstraction Layer, and contains a 'console' which will display the user's actions as they type in or delete text.

1. **Third tab:** demonstrates the mentions plug-in
   - Type in `@` or `+` to see a list of entities that you can select (for demonstration's sake, the [25 earliest Turing Award winners](http://amturing.acm.org/byyear.cfm))
   - You can also type in three characters of the name to bring up the built-in chooser


## :electric_plug: Plugins

Plugins are defined in the podspec file as subspecs, so you can pick and choose which plugins you want to use (as long as you include the Core subspec). If you are not using CocoaPods, each plug-in is located in a separate group in Xcode, and each plug-in's group can be deleted wholesale without compromising the functionality of the core library.

Hakawai supports two types of plugins, with both types receiving references to the parent `HKWTextView`:

1. **simple**: has access to all the APIs of & can reference the core `HKWTextView`

1. **control flow**: everything that `simple` plugins can do, plus the ability to implement additional delegate methods to respond to changes in the text view's state. Has two main subtypes, but please note that *only one* of the two subtypes can be registered to the text view at once:

   1. **direct control flow plugins:** receive `UITextViewDelegate` methods to monitor state of the text view and respond to user actions
   
   1. **abstraction layer control flow plugins:** receive `HKWAbstractionLayerDelegate` methods instead

Multiple simple plugins may be registered at once, but only one control flow plug-in can be registered at a time. Plugins can be unregistered at any time.


## :speech_balloon: The Mentions Plugin

*For more detailed documentation, check out the [Mentions page on the wiki](https://github.com/linkedin/Hakawai/wiki/Mentions).*

`Hakawai/Mentions` is a plugin that allows annotations to be created within a `HKWTextView`. Annotations are portions of text which refer to specific entities, treated as a monolithic unit, and can be styled differently from the rest of the text. Examples of annotations are the mentions feature supported by many popular social media applications.

To see `Mentions` in action, check out the included demo app. Or, download the LinkedIn iOS app from the App Store, log in with your LinkedIn account, and try mentioning a connection or company.


### Mentions Features

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


### Integrating Mentions

1. Create a helper class that implements the three required methods in `HKWMentionsDelegate`
2. Create an instance of `HKWTextView`
3. Create an instance of `HKWMentionsPlugin` using one of the factory methods
4. Set the mention plug-in's `delegate` property to an instance of your helper class
5. Call `registerControlFlowPlugin:` on the text view instance to register the plug-in

See the documentation comments for more information on the relevant classes and methods.


## :construction: Testing

Hakawai includes an almost-comprehensive unit test suite for the main text view powered by the [Specta and Expecta libraries](https://github.com/specta/specta). We hope to have test coverage for the abstraction layer and mentions plug-in in the future, although unit tests are probably not sufficient for testing these components.


## :pencil: Contributing

Bug reports, feature requests, pull requests, comments, criticism, and honest feedback are all welcome. Please [open an issue](https://github.com/linkedin/Hakawai/issues) if you can't find an existing one that matches.

We currently use version 1.5.0 of Cocoapods to manage dependencies.

Plans/known issues for this library include:

1. Verifying proper functionality and integration of Abstraction Layer

1. Proper handling of non-period punctuation inserted after a predictive suggestion is selected (right now, implicit deletion of space when it's replaced by the punctuation is not registered).

1. Abstraction Layer support for Korean text input

1. Automated testing

## :dragon: Etymology

According to [Wikipedia](https://en.wikipedia.org/wiki/Hakawai), "In Māori mythology, [...] Hakawai is a monstrous bird that ate people". There you go.

## :copyright: Copyright & License

Hakawai © 2019 LinkedIn Corp. Licensed under the terms of the Apache License, Version 2.0.
