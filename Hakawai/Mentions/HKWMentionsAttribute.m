//
//  HKWMentionsAttribute.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "HKWMentionsAttribute.h"

@interface HKWMentionsAttribute () <NSCopying>
@end

@implementation HKWMentionsAttribute

+ (instancetype)mentionWithText:(NSString *)text identifier:(NSString *)identifier {
    HKWMentionsAttribute *attr = [[self class] new];
    attr.mentionText = text;
    attr.entityIdentifier = identifier;
    attr.range = NSMakeRange(NSNotFound, 0);
    return attr;
}

- (NSString *)entityName {
    return self.mentionText;
}

- (NSString *)entityId {
    return self.entityIdentifier;
}

- (NSDictionary *)entityMetadata {
    return self.metadata;
}


#pragma mark - Private

- (id)copyWithZone:(NSZone *)zone {
    HKWMentionsAttribute *newAttr = [[self class] mentionWithText:self.mentionText
                                                                identifier:self.entityIdentifier];
    newAttr.range = self.range;
    newAttr.metadata = [self.metadata copy];
    return newAttr;
}

- (NSString *)description {
    if (self.range.location == NSNotFound) {
        return [NSString stringWithFormat:@"<0x%lx> (HKWMentionsAttribute) text: %@, id: %@, no range",
                (unsigned long)self,
                self.mentionText,
                self.entityIdentifier];
    }
    else {
        return [NSString stringWithFormat:@"<0x%lx> (HKWMentionsAttribute) text: %@, id: %@, location: %lu, length: \
                %lu",
                (unsigned long)self,
                self.mentionText,
                self.entityIdentifier,
                (unsigned long)self.range.location,
                (unsigned long)self.range.length];
    }
}

@end
