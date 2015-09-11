
#import <Foundation/Foundation.h>

extern NSString * const FTPSyncChilkatStarted;
extern NSString * const FTPSyncChilkatCompleted;
extern NSString * const FTPSyncChilkatFailed;

@interface FTPSyncChilkat : NSObject
@property BOOL allowItunesBackup; //after a sync completes the localDir will be set as do not backup.

- (id) initWithChilkatFTPKey:(NSString *) key host:(NSString *) host port:(NSUInteger) port secure:(BOOL) secure username:(NSString *) username password:(NSString *) password;
- (void) syncRemoteDirectory:(NSURL *) remoteDir toLocalDir:(NSURL *) localDir;
- (void) debugLog:(BOOL) debug;

@end
