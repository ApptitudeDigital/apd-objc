
#import <Foundation/Foundation.h>

//notifications
extern NSString * const FTPSyncChilkatStarted;
extern NSString * const FTPSyncChilkatCompleted;
extern NSString * const FTPSyncChilkatFailed;

@class FTPSyncChilkat;

//delegate
@protocol FTPSyncChilkatDelegate <NSObject>
@optional
- (void) ftpSyncChilkatDidStart:(FTPSyncChilkat *) ftpSync;
- (void) ftpSyncChilkatDidFail:(FTPSyncChilkat *) ftpSync;
- (void) ftpSyncChilkatDidComplete:(FTPSyncChilkat *) ftpSync;
@end

@interface FTPSyncChilkat : NSObject

//use the delegate if you don't want to use notifications.
@property NSObject <FTPSyncChilkatDelegate> * delegate;

//if false after a sync completes the localDir will be set as do not backup.
//defaults to true.
@property BOOL allowItunesBackup;


- (id) initWithChilkatFTPKey:(NSString *) key host:(NSString *) host port:(NSUInteger) port secure:(BOOL) secure username:(NSString *) username password:(NSString *) password;

- (void) syncRemoteDirectory:(NSURL *) remoteDir toLocalDir:(NSURL *) localDir;
//see SyncLocalTree for mode option docs (default is 5) https://www.chilkatsoft.com/refdoc/objcCkoFtp2Ref.html
- (void) syncRemoteDirectory:(NSURL *) remoteDir toLocalDir:(NSURL *) localDir withSyncMode:(NSUInteger) mode;

- (void) debugLog:(BOOL) debug;

@end
