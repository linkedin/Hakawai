/*!
 This is being used for consumer of the library that wants to provide its own custom chooser view.
 The consumer is responsible for data processing, cool down logic and UI setup.
 */
@protocol HKWMentionsCustomChooserViewDelegate <NSObject>

/*!
 Notify the delegate that key string for the mentions query has been updated. Delegate then can fetch the mentions results. Upon
 completion, it will call `dataReturnedWithEmptyResults:keystringEndsWithWhiteSpace:` to notify the mentions plugin.

 \param keyString          the string that the data source should search upon
 \param character          if \c type is Explicit, this is the control character that was typed to begin the
                           mention creation; otherwise, it should be ignored
 */
- (void)didUpdateKeyString:(nonnull NSString *)keyString
          controlCharacter:(unichar)character;

@optional

/*!
 Return whether or not a given mentions entity can be 'trimmed' - that is, if the entity name is multiple words, it can
 be reduced to just the first word. If not implemented, the plug-in assumes that no entities can be trimmed. Trimming
 is irrelevant for entities that start out with single-word names, unless \c trimmedNameForEntity: is implemented, in
 which case the plug-in will query even for entities with single-word names.
 */
- (BOOL)entityCanBeTrimmed:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity;

@end
