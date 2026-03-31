//
//  PingOperation.m
//  WhiteLabel-Test
//
//  Created by Michael Mavris on 03/11/2016.
//  Copyright © 2016 Miksoft. All rights reserved.
//

#import "PingOperation.h"
#import "MMDevice.h"
#import "LANProperties.h"
#import "MacFinder.h"

static const float PING_TIMEOUT = 1;
static const float PING_MAX_LIFETIME = 5;

@interface PingOperation ()
@property (nonatomic,strong) NSString *ipStr;
@property (nonatomic,strong) NSDictionary *brandDictionary;
@property(nonatomic,strong)SimplePing *simplePing;
@property (nonatomic, copy) void (^result)(NSError  * _Nullable error, NSString  * _Nonnull ip);
@end

@interface PingOperation()
- (void)finish;
@end

@implementation PingOperation {
    BOOL _stopRunLoop;
    BOOL _isFinishing;
    NSTimer *_keepAliveTimer;
    NSError *errorMessage;
    NSTimer *pingTimer;
}

-(instancetype)initWithIPToPing:(NSString*)ip andCompletionHandler:(nullable void (^)(NSError  * _Nullable error, NSString  * _Nonnull ip))result;{

    self = [super init];
    
    if (self) {
        self.name = ip;
        _ipStr= ip;
        _simplePing = [SimplePing simplePingWithHostName:ip];
        _simplePing.delegate = self;
        _result = result;
        _isExecuting = NO;
        _isFinished = NO;
    }
    
    return self;
};

-(void)start {

    if ([self isCancelled]) {
        [self willChangeValueForKey:@"isFinished"];
        _isFinished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    
    
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    // Safety timeout: ensures the operation finishes even if all delegate callbacks are lost
    _keepAliveTimer = [NSTimer timerWithTimeInterval:PING_MAX_LIFETIME target:self selector:@selector(timeout:) userInfo:nil repeats:NO];
    [runLoop addTimer:_keepAliveTimer forMode:NSDefaultRunLoopMode];
    
    //Ping method
    [self ping];
    
    NSTimeInterval updateInterval = 0.1f;
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:updateInterval];
    
    while (!_stopRunLoop && [runLoop runMode: NSDefaultRunLoopMode beforeDate:loopUntil]) {
        loopUntil = [NSDate dateWithTimeIntervalSinceNow:updateInterval];
    }

}
-(void)ping {
    [self.simplePing start];
}
- (void)finishedPing {
    if (_isFinishing) return;
    _isFinishing = YES;
    
    [pingTimer invalidate];
    pingTimer = nil;
    [self.simplePing stop];
    self.simplePing.delegate = nil;
    
    if (self.result) {
        self.result(errorMessage,self.name);
    }
    
    [self finish];
}

- (void)timeout:(NSTimer*)timer
{
    //This method should never get called. (just in case)
    errorMessage = [NSError errorWithDomain:@"Ping Timeout" code:10 userInfo:nil];
    [self finishedPing];
}

-(void)finish {

    [NSObject cancelPreviousPerformRequestsWithTarget:self.simplePing];
    
    //Removes timer from the NSRunLoop
    [_keepAliveTimer invalidate];
    _keepAliveTimer = nil;
    
    //Kill the while loop in the start method
    _stopRunLoop = YES;
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
    
}

- (BOOL)isExecuting {
    return _isExecuting;
}

- (BOOL)isFinished {
    return _isFinished;
}
#pragma mark - Pinger delegate

// When the pinger starts, send the ping immediately
- (void)simplePing:(SimplePing *)pinger didStartWithAddress:(NSData *)address {
    
    if (self.isCancelled) {
        [self finish];
        return;
    }
    
    [pinger sendPingWithData:nil];
}

- (void)simplePing:(SimplePing *)pinger didFailWithError:(NSError *)error {
    errorMessage = error;
    [self finishedPing];
}

- (void)simplePing:(SimplePing *)pinger didFailToSendPacket:(NSData *)packet error:(NSError *)error {
    errorMessage = error;
    [self finishedPing];
}

- (void)simplePing:(SimplePing *)pinger didReceivePingResponsePacket:(NSData *)packet {
    [self finishedPing];
}

- (void)simplePing:(SimplePing *)pinger didSendPacket:(NSData *)packet {
    //This timer will fired pingTimeOut in case the SimplePing don't answer in the specific time
    pingTimer = [NSTimer scheduledTimerWithTimeInterval:PING_TIMEOUT target:self selector:@selector(pingTimeOut:) userInfo:nil repeats:NO];
}

- (void)pingTimeOut:(NSTimer *)timer {
    // Move to next host
    errorMessage = [NSError errorWithDomain:@"Ping timeout" code:11 userInfo:nil];
    [self finishedPing];
}

@end
