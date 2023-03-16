//
//  HKWTextView+TextTransformation.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWTextView+TextTransformation.h"

#import "_HKWTextView.h"

@implementation HKWTextView (TextTransformation)

#pragma mark - API (text)

- (void)transformSelectedTextWithTransformer:(NSAttributedString *(^)(NSAttributedString *))transformer {
    NSRange selectedRange = self.selectedRange;
    if (!transformer || selectedRange.location == NSNotFound) {
        return;
    }
    [self transformTextAtRange:selectedRange withTransformer:transformer];
}

/**
 QuickPath keyboard will hold a NSConditionLock on attributedText while accessing it at the same time results in a deadlock. Calling main queue
 to make sure it won't be synchronized to cause a deadlock. Apple Feedback Tracking number: [OpenRadar:6828895]
 */
- (void)transformTextAtRange:(NSRange)range
             withTransformer:(NSAttributedString *(^)(NSAttributedString *))transformer {
    [self transformTextAtRangeImpl:range withTransformer:transformer];
}

- (void)transformTextAtRangeImpl:(NSRange)range
                 withTransformer:(NSAttributedString *(^)(NSAttributedString *))transformer {
    BOOL usingAbstraction = self.abstractionLayerEnabled;
    if (transformer && [self.attributedText length] == 0 && range.location == 0) {
        // Special case: text view text is empty; beginning is valid
        if (usingAbstraction) {
            [self.abstractionLayer pushIgnore];
        }
        self.shouldRejectAutocorrectInsertions = YES;
        self.attributedText = transformer(nil);
        self.shouldRejectAutocorrectInsertions = NO;
        if (usingAbstraction) {
            [self.abstractionLayer popIgnore];
        }
        return;
    }
    if (!transformer
        || range.location == NSNotFound
        || range.location > [self.attributedText length]) {
        return;
    }

    if (usingAbstraction) {
        [self.abstractionLayer pushIgnore];
    }
    BOOL shouldRestore = self.selectedRange.length == 0 && self.selectedRange.location != NSNotFound;
    NSRange originalSelectedRange = self.selectedRange;
    self.transformInProgress = YES;
    NSUInteger end = range.length + range.location;
    if (end > [self.attributedText length]) {
        // Trim the range if it extends past the end of the string.
        end = [self.attributedText length];
        range.length = [self.attributedText length] - range.location;
    }
    NSAttributedString *originalInfix = [self.attributedText attributedSubstringFromRange:range];
    NSAttributedString *prefixString = [self.attributedText attributedSubstringFromRange:NSMakeRange(0, range.location)];
    NSAttributedString *infixString = transformer(originalInfix);
    NSAttributedString *postfixString = [self.attributedText attributedSubstringFromRange:NSMakeRange(end, [self.attributedText length] - end)];
    NSMutableAttributedString *buffer = [[NSMutableAttributedString alloc] initWithAttributedString:prefixString];
    if (infixString) [buffer appendAttributedString:infixString];
    if (postfixString) [buffer appendAttributedString:postfixString];

    // We turn on 'autocorrect insertion rejection' before we set the text in order to reject a spurious additional
    //  call to the shouldChange... method in the text view delegate
    self.shouldRejectAutocorrectInsertions = YES;
    self.attributedText = buffer;
    self.shouldRejectAutocorrectInsertions = NO;

    if (shouldRestore && range.length == [infixString length]) {
        // If the replacement text and the original text are the same length, restore the insertion cursor to its
        //  original position.
        self.selectedRange = originalSelectedRange;
    }
    self.transformInProgress = NO;
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textView:didChangeAttributedTextTo:originalText:originalRange:)]) {
        [externalDelegate textView:self didChangeAttributedTextTo:infixString originalText:originalInfix originalRange:range];
    }
    if (usingAbstraction) {
        [self.abstractionLayer popIgnore];
    }
}

- (void)insertPlainText:(NSString *)text location:(NSUInteger)location {
    [self insertAttributedText:[[NSAttributedString alloc] initWithString:text attributes:self.typingAttributes]
                      location:location];
}

- (void)insertAttributedText:(NSAttributedString *)text location:(NSUInteger)location {
    if ([text length] == 0) return;
    NSAttributedString *(^transformer)(NSAttributedString *) = ^(__unused NSAttributedString *input) {
        return text;
    };
    [self transformTextAtRange:NSMakeRange(location, 0) withTransformer:transformer];
}

/**
 QuickPath keyboard will hold a NSConditionLock on attributedText while accessing to it at the same time results in a deadlock. Calling main queue
 to make sure it won't be synchronized to cause a deadlock. Apple Feedback Tracking number: [FB6828895]
 */
-(void)insertTextAttachment:(NSTextAttachment *)attachment location:(NSUInteger)location {
    [self insertTextAttachmentImpl:attachment location:location];
}

- (void)insertTextAttachmentImpl:(NSTextAttachment *)attachment location:(NSUInteger)location {
    if (!attachment) return;
    BOOL usingAbstraction = self.abstractionLayerEnabled;
    if ([self.attributedText length] == 0) {
        // Special case: text view text is empty; index is valid
        if (usingAbstraction) {
            [self.abstractionLayer pushIgnore];
        }
        if (location == 0) {
            self.shouldRejectAutocorrectInsertions = YES;
            self.attributedText = [NSAttributedString attributedStringWithAttachment:attachment];
            self.shouldRejectAutocorrectInsertions = NO;
        }
        if (usingAbstraction) {
            [self.abstractionLayer popIgnore];
        }
        return;
    }
    if (usingAbstraction) {
        [self.abstractionLayer pushIgnore];
    }
    if (location >= [self.attributedText length]) {
        location = [self.attributedText length] - 1;
    }
    [self insertAttributedText:[NSAttributedString attributedStringWithAttachment:attachment] location:location];
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textView:didReceiveNewTextAttachment:)]) {
        [externalDelegate textView:self didReceiveNewTextAttachment:attachment];
    }
    if (usingAbstraction) {
        [self.abstractionLayer popIgnore];
    }
}

- (void)removeTextForRange:(NSRange)range {
    if ([self.attributedText length] == 0
        || range.location == NSNotFound
        || range.location >= [self.attributedText length]
        || range.length == 0) {
        return;
    }
    NSAttributedString *(^transformer)(NSAttributedString *) = ^(__unused NSAttributedString *input) {
        return (NSAttributedString *)nil;
    };
    [self transformTextAtRange:range withTransformer:transformer];
}


#pragma mark - API (attributes)

- (void)activateCustomAttributeWithName:(NSString *)name value:(id)value {
    if ([name length] == 0 || !value) {
        return;
    }
    self.customTypingAttributes[name] = value;
}

- (void)deactivateCustomAttributeWithName:(NSString *)name {
    if ([name length] == 0) {
        return;
    }
    [self.customTypingAttributes removeObjectForKey:name];
}

- (void)deactivateAllCustomAttributes {
    [self.customTypingAttributes removeAllObjects];
}

- (void)stripAttributeFromTextAtRange:(NSRange)range attributeName:(NSString *)attributeName {
    if (range.length == 0 || range.location == NSNotFound || [attributeName length] == 0) {
        return;
    }
    NSAttributedString *(^transformer)(NSAttributedString *) = ^(NSAttributedString *input) {
        NSMutableAttributedString *buffer = [input mutableCopy];
        [buffer removeAttribute:attributeName range:NSMakeRange(0, [input length])];
        return [buffer copy];
    };
    [self transformTextAtRange:range withTransformer:transformer];
}

- (void)transformTypingAttributesWithTransformer:(NSDictionary *(^)(NSDictionary *currentAttributes))transformer {
    if (!transformer) return;
    self.typingAttributes = transformer(self.typingAttributes);
}

@end
