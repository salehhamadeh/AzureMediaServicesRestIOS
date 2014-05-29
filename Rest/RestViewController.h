//
//  RestViewController.h
//  Rest
//
//  Created by Saleh Hamadeh on 5/22/14.
//  Copyright (c) 2014 Spring. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RestViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *greetingId;
@property (nonatomic, strong) IBOutlet UILabel *greetingContent;

@property (nonatomic, strong) NSString *accessToken;

- (IBAction)uploadVideoToAzure;
@end
