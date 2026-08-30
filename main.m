// frontmost -- print what is in front on the device, as one line of JSON.
//
//     {"bundleId":"com.purepoker.world.app","name":"Pure Poker","pid":770}
//
// or `{}` when nothing is: the lock screen, the home screen, the app
// switcher. The exit status is 0 in both cases. Anything else is a failure
// to ask, and bookie-jb reports it as such rather than guessing.
//
// Asked of SpringBoardServices, which is what every "what is in front" tool
// on a jailbroken device has asked since there were jailbroken devices. The
// three calls are private API and are declared here by hand because the
// framework ships no headers; their shapes have not changed in a decade.
//
// Built with theos from the Makefile beside this file. See README.md.

#import <Foundation/Foundation.h>

extern CFStringRef SBSCopyFrontmostApplicationDisplayIdentifier(void);
extern CFStringRef SBSCopyLocalizedApplicationNameForDisplayIdentifier(CFStringRef displayIdentifier);
extern pid_t SBSProcessIDForDisplayIdentifier(CFStringRef displayIdentifier);

int main(int argc, char **argv) {
    @autoreleasepool {
        NSMutableDictionary<NSString *, id> *report = [NSMutableDictionary dictionary];

        CFStringRef identifier = SBSCopyFrontmostApplicationDisplayIdentifier();
        if (identifier != NULL) {
            NSString *bundleId = (__bridge_transfer NSString *)identifier;
            report[@"bundleId"] = bundleId;

            CFStringRef name = SBSCopyLocalizedApplicationNameForDisplayIdentifier(
                (__bridge CFStringRef)bundleId);
            if (name != NULL) {
                report[@"name"] = (__bridge_transfer NSString *)name;
            }

            pid_t pid = SBSProcessIDForDisplayIdentifier((__bridge CFStringRef)bundleId);
            if (pid > 0) {
                report[@"pid"] = @(pid);
            }
        }

        NSError *error = nil;
        NSData *json = [NSJSONSerialization dataWithJSONObject:report options:0 error:&error];
        if (json == nil) {
            fprintf(stderr, "frontmost: %s\n", error.localizedDescription.UTF8String);
            return 1;
        }
        fwrite(json.bytes, 1, json.length, stdout);
        fputc('\n', stdout);
        return 0;
    }
}
