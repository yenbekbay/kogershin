#import "NSDate+KSHelpers.h"

@implementation NSDate (KSHelpers)

- (NSString *)dateString {
    NSLocale *ruLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"ru"];
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMMd, HH:mm" options:0 locale:ruLocale];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.locale = ruLocale;
    dateFormatter.dateFormat = dateFormat;
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:60*60*6];
    return [dateFormatter stringFromDate:self];
}

@end
