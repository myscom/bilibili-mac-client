//
//  PostComment.m
//  bilibili
//
//  Created by TYPCN on 2015/4/4.
//  Copyright (c) 2015 TYPCN. All rights reserved.
//

#import "PostComment.h"
#import "client.h"

extern NSString *vAID;
extern NSString *vPID;
extern NSString *vCID;
extern NSString *userAgent;
extern mpv_handle *mpv;

@interface PostComment (){
    BOOL posted;
    __weak IBOutlet NSSegmentedControl *CommentTypeSelecter;
}

@end

@implementation PostComment

- (void)viewDidLoad {
    [super viewDidLoad];
    //[self.view.window makeKeyWindow];
    //[self.view.window makeFirstResponder:self];
    posted = false;
}
- (IBAction)Send:(id)sender {
    if(posted){
        return;
    }
    
    posted = true;
    
    NSString *text = [sender stringValue];
    if([text length] > 0){
        char *time = mpv_get_property_string(mpv,"playback-time");
        NSString *playTime = [NSString stringWithCString:time encoding:NSUTF8StringEncoding];
        NSLog(@"Posting comment in %@",playTime);
        
        
        NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://interface.bilibili.com/dmpost?cid=%@&aid=%@&pid=%@",vCID,vAID,vPID]];
        if([vAID isEqualToString:@"LIVE"]){
            URL = [NSURL URLWithString:@"http://live.bilibili.com/msg/send"];
        }
        
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
        request.HTTPMethod = @"POST";
        request.timeoutInterval = 5;
        
        // Get Date
        
        NSDateFormatter *format = [[NSDateFormatter alloc] init];
        [format setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *now = [[NSDate alloc] init];
        NSString *dateString = [format stringFromDate:now];
        
        // Body
        
        
        NSString *mode = @"1";
        if([CommentTypeSelecter selectedSegment] == 0){
            mode = @"5";
        }else if([CommentTypeSelecter selectedSegment] == 2){
            mode = @"4";
        }
        NSLog(@"Comment mode %@",mode);
        
        NSDictionary* bodyParameters = @{
                                         @"cid": vCID,
                                         @"color": @"16777215",
                                         @"mode": mode,
                                         @"pool": @"0",
                                         @"fontsize": @"25",
                                         @"date": dateString,
                                         @"message": text,
                                         @"playTime": playTime,
                                         };
        
        if([vAID isEqualToString:@"LIVE"]){
            bodyParameters = @{
                               @"roomid": vCID,
                               @"color": @"16777215",
                               @"mode": @"1",
                               @"fontsize": @"25",
                               @"msg": text,
                               };
        }
        
        request.HTTPBody = [NSStringFromQueryParameters(bodyParameters) dataUsingEncoding:NSUTF8StringEncoding];
        
        // Headers
        
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request addValue:userAgent forHTTPHeaderField:@"User-Agent"];
        [request setValue:@"http://static.hdslb.com" forHTTPHeaderField:@"Origin"];
        [request setValue:@"http://static.hdslb.com/play.swf" forHTTPHeaderField:@"Referer"];
        [request setValue:@"ShockwaveFlash/17.0.0.188" forHTTPHeaderField:@"X-Requested-With"];
        // Cookies will add automatically
        
        if([vAID isEqualToString:@"LIVE"]){
            [request setValue:@"http://static.hdslb.com/live-static/swf/LivePlayerEx_1.swf" forHTTPHeaderField:@"Referer"];
        }
        
        // Send Request
        
        NSURLResponse * response = nil;
        NSError * error = nil;
        NSData * data = [NSURLConnection sendSynchronousRequest:request
                                              returningResponse:&response
                                                          error:&error];
        NSString *returnData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if([returnData length] > 0){
            int x = [returnData intValue];
            if (x > -1){
                [sender setStringValue:NSLocalizedString(@"😁发送成功！", nil)];
                NSLog(@"Comment sent. ID: %d",x);
            }else{
                [sender setStringValue:[NSString stringWithFormat:NSLocalizedString(@"😢发送失败 错误码 %d", nil),x]];
                NSLog(@"Comment send failed. Error code: %d",x);
            }
        }else{
            [sender setStringValue:NSLocalizedString(@"😡简直日了狗了！没发出去！", nil)];
            NSLog(@"Comment send failed. Empty response");
        }
        double delayInSeconds = 3.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [sender setStringValue:@""];
            [self.view.window close];
        });
    }else{
        [self.view.window close];
    }
}

/*
 * Utils: Add this section before your class implementation
 */

/**
 This creates a new query parameters string from the given NSDictionary. For
 example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
 string will be @"day=Tuesday&month=January".
 @param queryParameters The input dictionary.
 @return The created parameters string.
 */
static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

@end

@interface PostCommentWindow : NSWindow <NSWindowDelegate>

@end

@implementation PostCommentWindow{
    
}

- (BOOL)canBecomeMainWindow { return YES; }
- (BOOL)canBecomeKeyWindow { return YES; }
- (BOOL) becomeFirstResponder { return YES; }
- (BOOL) resignFirstResponder { return YES; }

@end