// frontmost -- print what is in front on the device, as one line of JSON.
//
//     {"bundleId":"com.purepoker.world.app","name":"Pure Poker","pid":770}
//
// or `{}` when nothing is: the lock screen, the home screen, the app
// switcher. The exit status is 0 in both cases. Anything else is a failure
// to ask, and bookie-jb reports it as such rather than guessing.
//
// Two ways of asking, tried in order. SpringBoardServices' own answer, which
// is what every "what is in front" tool on a jailbroken device used to give,
// and which SpringBoard on iOS 15 hands to nobody this tool can be -- it
// returns NULL to root and mobile alike, with or without the entitlements
// once thought to unlock it. So the answer that counts comes from BackBoard:
// the state of every installed app, from which exactly one is in the
// foreground-running state, and that one is in front. Measured on an iPad
// mini 4 on 15.8.2 under RootHide: Safari in front reads 8, everything else
// running reads 2, and the home screen reads no 8 at all.
//
// The name comes from the same app record BackBoard was asked about, and the
// pid from the kernel's own process list, matched by executable path. Neither
// is asked of SpringBoard, which on this device answers those with nothing
// and with 1 respectively.
//
// The calls are private API and are declared here by hand, or looked up at
// run time, because the frameworks ship no headers.
//
// `frontmost --debug` says more, for a device where the answer is `{}` when
// it should not be: who asked, which route answered, and what each saw.
//
// Built with theos from the Makefile beside this file. See README.md.

#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <sys/param.h>
#import <unistd.h>

extern CFStringRef SBSCopyFrontmostApplicationDisplayIdentifier(void);
extern CFArrayRef SBSCopyApplicationDisplayIdentifiers(bool onlyActive, bool debuggable);

// libproc, present in libSystem on iOS and declared in no public header.
extern int proc_listallpids(void *buffer, int buffersize);
extern int proc_pidpath(int pid, void *buffer, uint32_t buffersize);
#define PROC_PIDPATHINFO_MAXSIZE (4 * MAXPATHLEN)

// BKSApplicationState, from BackBoardServices. The foreground bit is the one
// that matters; the rest are reported under --debug and read by nobody.
enum {
    kForegroundRunning = 1 << 3,
};

typedef id (*ObjectCall)(id, SEL);
typedef id (*ObjectCallWithObject)(id, SEL, id);
typedef NSUInteger (*UnsignedCallWithObject)(id, SEL, id);

static NSString *frontmostFromSpringBoard(void) {
    CFStringRef identifier = SBSCopyFrontmostApplicationDisplayIdentifier();
    return identifier != NULL ? (__bridge_transfer NSString *)identifier : nil;
}

// Every installed app, by bundle id, as LSApplicationProxy objects.
static NSDictionary<NSString *, id> *installedApps(void) {
    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    if (workspaceClass == nil) return @{};
    id workspace = ((ObjectCall)objc_msgSend)(workspaceClass, @selector(defaultWorkspace));
    NSArray *proxies = ((ObjectCall)objc_msgSend)(workspace, @selector(allInstalledApplications));
    NSMutableDictionary<NSString *, id> *apps = [NSMutableDictionary dictionary];
    for (id proxy in proxies) {
        NSString *bundleId = ((ObjectCall)objc_msgSend)(proxy, @selector(applicationIdentifier));
        if (bundleId != nil) apps[bundleId] = proxy;
    }
    return apps;
}

// Every running app's state according to BackBoard, keyed by bundle id.
static NSDictionary<NSString *, NSNumber *> *statesFromBackBoard(NSDictionary<NSString *, id> *apps) {
    Class monitorClass = NSClassFromString(@"BKSApplicationStateMonitor");
    if (monitorClass == nil) return @{};
    id monitor = [[monitorClass alloc] init];
    NSMutableDictionary<NSString *, NSNumber *> *states = [NSMutableDictionary dictionary];
    for (NSString *bundleId in apps) {
        NSUInteger state = ((UnsignedCallWithObject)objc_msgSend)(
            monitor, @selector(applicationStateForApplication:), bundleId);
        if (state != 0) states[bundleId] = @(state);
    }
    ((ObjectCall)objc_msgSend)(monitor, @selector(invalidate));
    return states;
}

static NSString *frontmostFromBackBoard(NSDictionary<NSString *, NSNumber *> *states) {
    for (NSString *bundleId in states) {
        if (states[bundleId].unsignedIntegerValue & kForegroundRunning) return bundleId;
    }
    return nil;
}

// The pid of the process whose executable lives inside the app's bundle.
static pid_t pidForBundle(id proxy) {
    NSURL *bundleURL = ((ObjectCall)objc_msgSend)(proxy, @selector(bundleURL));
    NSString *bundlePath = bundleURL.path;
    if (bundlePath.length == 0) return 0;
    NSString *prefix = [bundlePath stringByAppendingString:@"/"];

    int count = proc_listallpids(NULL, 0);
    if (count <= 0) return 0;
    count += 16;  // room for processes that appear between the two calls
    pid_t *pids = calloc((size_t)count, sizeof(pid_t));
    if (pids == NULL) return 0;
    count = proc_listallpids(pids, count * (int)sizeof(pid_t));
    pid_t found = 0;
    char path[PROC_PIDPATHINFO_MAXSIZE];
    for (int i = 0; i < count && found == 0; i++) {
        if (pids[i] <= 0) continue;
        if (proc_pidpath(pids[i], path, sizeof(path)) <= 0) continue;
        if (strncmp(path, prefix.UTF8String, strlen(prefix.UTF8String)) == 0) found = pids[i];
    }
    free(pids);
    return found;
}

int main(int argc, char **argv) {
    @autoreleasepool {
        BOOL debug = argc > 1 && strcmp(argv[1], "--debug") == 0;
        NSMutableDictionary<NSString *, id> *report = [NSMutableDictionary dictionary];

        NSDictionary<NSString *, id> *apps = installedApps();
        NSDictionary<NSString *, NSNumber *> *states = nil;
        NSString *bundleId = frontmostFromSpringBoard();
        NSString *route = bundleId ? @"springboard" : nil;
        if (bundleId == nil) {
            states = statesFromBackBoard(apps);
            bundleId = frontmostFromBackBoard(states);
            route = bundleId ? @"backboard" : nil;
        }

        if (bundleId != nil) {
            report[@"bundleId"] = bundleId;
            id proxy = apps[bundleId];
            if (proxy != nil) {
                NSString *name = ((ObjectCall)objc_msgSend)(proxy, @selector(localizedName));
                if (name.length > 0) report[@"name"] = name;
                pid_t pid = pidForBundle(proxy);
                if (pid > 0) report[@"pid"] = @(pid);
            }
        }

        if (debug) {
            report[@"uid"] = @(geteuid());
            report[@"route"] = route ?: [NSNull null];
            CFArrayRef active = SBSCopyApplicationDisplayIdentifiers(true, false);
            report[@"springboardActive"] = active != NULL ? (__bridge_transfer NSArray *)active : [NSNull null];
            if (states == nil) states = statesFromBackBoard(apps);
            report[@"backboardStates"] = states;
            report[@"installed"] = @(apps.count);
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
