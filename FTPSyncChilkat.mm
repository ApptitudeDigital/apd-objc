
#import "FTPSyncChilkat.h"
#import "CkoFtp2.h"
#import "CkoTask.h"

NSString * const FTPSyncChilkatCompleted = @"FTPSyncChilkatCompleted";
NSString * const FTPSyncChilkatFailed = @"FTPSyncChilkatFailed";

@interface FTPSyncChilkat ()
@property BOOL secure;
@property NSURL * remoteDir;
@property NSURL * localDir;
@property CkoFtp2 * chilkatFTP;
@property CkoTask * currentTask;
@property NSTimer * taskMonitor;
@property NSString * currentTaskName;
@end

@implementation FTPSyncChilkat

- (id) initWithFTPKey:(NSString *) key host:(NSString *) host port:(NSUInteger) port secure:(BOOL) secure username:(NSString *) username password:(NSString *) password {
	self = [super init];
	self.allowItunesBackup = TRUE;
	
	//unlock
	self.chilkatFTP = [[CkoFtp2 alloc] init];
	if([self.chilkatFTP UnlockComponent:key] != TRUE) {
		NSLog(@"Chilkat key: (%@) failed to unlock",key);
		[[NSNotificationCenter defaultCenter] postNotificationName:FTPSyncChilkatFailed object:nil];
		return nil;
	}
	
	self.chilkatFTP.Hostname = host;
	self.chilkatFTP.Username = username;
	self.chilkatFTP.Password = password;
	self.chilkatFTP.Port = @(port);
	self.secure = secure;
	
	if(secure) {
		self.chilkatFTP.AuthTls = TRUE;
	}
	
	return self;
}

- (void) dealloc {
	if(self.currentTask) {
		[self.currentTask Cancel];
	}
	[self.chilkatFTP Disconnect];
}

- (void) syncRemoteDirectory:(NSURL *) remoteDir toLocalDir:(NSURL *) localDir; {
	NSLog(@"FTP Sync Remote Dir: %@",remoteDir.path);
	NSLog(@"FTP Sync Local Dir: %@",localDir.path);
	self.remoteDir = remoteDir;
	self.localDir = localDir;
	BOOL isdir;
	if(![[NSFileManager defaultManager] fileExistsAtPath:localDir.path isDirectory:&isdir]) {
		[[NSFileManager defaultManager] createDirectoryAtPath:localDir.path withIntermediateDirectories:TRUE attributes:nil error:nil];
	}
	[self connect];
}

- (void) stopMonitor {
	[self.taskMonitor invalidate];
	self.taskMonitor = nil;
}

- (void) startMonitor {
	[self stopMonitor];
	self.taskMonitor = [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(checkTask:) userInfo:nil repeats:TRUE];
}

- (void) checkTask:(NSTimer *) timer {
	//http://www.chilkatsoft.com/refdoc/objcCkoFtp2Ref.html
	//NSLog(@"current task finished: %i",self.currentTask.Finished);
	//NSLog(@"status: %@",self.currentTask.Status);
	
	if(self.currentTask.Finished) {
		if(self.currentTask.StatusInt.integerValue != 7) {
			NSLog(@"StatusInt != 7 (%@, secure:%i) failed",self.currentTaskName,self.secure);
			[[NSNotificationCenter defaultCenter] postNotificationName:FTPSyncChilkatFailed object:nil];
			[self stopMonitor];
			return;
		}
		
		if([self.currentTask GetResultBool] != TRUE) {
			NSLog(@"GetResultBool failed (%@, secure: %i) failed",self.currentTaskName,self.secure);
			[[NSNotificationCenter defaultCenter] postNotificationName:FTPSyncChilkatFailed object:nil];
			[self stopMonitor];
			return;
		}
		
		if([self.currentTaskName isEqualToString:@"ConnectAsync"]) {
			[self changeDir];
		}
		
		else if([self.currentTaskName isEqualToString:@"ChangeRemoteDirAsync"]) {
			[self sync];
		}
		
		else if([self.currentTaskName isEqualToString:@"SyncLocalTreeAsync"]) {
			[self completed];
		}
	}
}

- (void) debugLog:(BOOL) debug; {
	if(debug) {
		self.chilkatFTP.DebugLogFilePath = [NSTemporaryDirectory() stringByAppendingString:@"chilkat-ftp.log"];
		NSLog(@"Chilkat Debug File: %@",self.chilkatFTP.DebugLogFilePath);
	} else {
		self.chilkatFTP.DebugLogFilePath = nil;
		NSLog(@"Chilkat Debug Turned Off");
	}
}

- (void) completed {
	NSLog(@"Chilkat FTP Sync Completed");
	[[NSNotificationCenter defaultCenter] postNotificationName:FTPSyncChilkatCompleted object:nil];
	[self stopMonitor];
	if(!self.allowItunesBackup) {
		[self.localDir setResourceValue:@(1) forKey:NSURLIsExcludedFromBackupKey error:nil];
	}
}

- (void) connect {
	self.currentTask = [self.chilkatFTP ConnectAsync];
	self.currentTaskName = @"ConnectAsync";
	if([self.currentTask Run] != TRUE) {
		NSLog(@"Chilkat ConnectAsync failed");
		[[NSNotificationCenter defaultCenter] postNotificationName:FTPSyncChilkatFailed object:nil];
		return;
	}
	[self startMonitor];
}

- (void) changeDir {
	self.currentTask = [self.chilkatFTP ChangeRemoteDirAsync:self.remoteDir.path];
	self.currentTaskName = @"ChangeRemoteDirAsync";
	if([self.currentTask Run] != TRUE) {
		[self.chilkatFTP Disconnect];
		NSLog(@"Chilkat ChangeRemoteDir (%@) failed",self.remoteDir.path);
		[[NSNotificationCenter defaultCenter] postNotificationName:FTPSyncChilkatFailed object:nil];
		return;
	}
	[self startMonitor];
}

- (void) sync {
	self.currentTask = [self.chilkatFTP SyncLocalTreeAsync:self.localDir.path mode:@(5)];
	self.currentTaskName = @"SyncLocalTreeAsync";
	if([self.currentTask Run] != YES) {
		[self.chilkatFTP Disconnect];
		NSLog(@"Chilkat SyncLocalTreeAsync (%@) failed",self.localDir.path);
		[[NSNotificationCenter defaultCenter] postNotificationName:FTPSyncChilkatFailed object:nil];
		return;
	}
	[self startMonitor];
}

@end
