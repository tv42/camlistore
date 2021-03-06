//
//  LAViewController.m
//  photobackup
//
//  Created by Nick O'Neill on 10/20/13.
//  Copyright (c) 2013 The Camlistore Authors. All rights reserved.
//

#import "LAViewController.h"
#import "LACamliClient.h"
#import "LAAppDelegate.h"
#import "LACamliUtil.h"
#import "SettingsViewController.h"
#import "LACamliUploadOperation.h"
#import "UploadStatusCell.h"
#import "UploadTaskCell.h"

@implementation LAViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.operations = [NSMutableArray array];

    self.navigationItem.title = @"camlistore";

    UIBarButtonItem *settingsItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(showSettings)];

    [self.navigationItem setRightBarButtonItem:settingsItem];

    NSURL *serverURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:CamliServerKey]];
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:CamliUsernameKey];

    NSString *password = nil;
    if (username) {
        password = [LACamliUtil passwordForUsername:username];
    }

    if (!serverURL || !username || !password) {
        [self showSettings];
    }

    [[NSNotificationCenter defaultCenter] addObserverForName:@"statusText" object:nil queue:nil usingBlock:^(NSNotification *note) {
        UploadStatusCell *cell = (UploadStatusCell *)[_table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

        dispatch_async(dispatch_get_main_queue(), ^{
            cell.status.text = note.object[@"text"];
        });
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:@"errorText" object:nil queue:nil usingBlock:^(NSNotification *note) {
        UploadStatusCell *cell = (UploadStatusCell *)[_table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

        dispatch_async(dispatch_get_main_queue(), ^{
            cell.error.text = note.object[@"text"];
        });
    }];
}

- (void)showSettings
{
    SettingsViewController *settings = [self.storyboard instantiateViewControllerWithIdentifier:@"settings"];
    [settings setParent:self];

    [self presentViewController:settings animated:YES completion:nil];
}

- (void)dismissSettings
{
    [self dismissViewControllerAnimated:YES completion:nil];

    [(LAAppDelegate *)[[UIApplication sharedApplication] delegate] loadCredentials];
}

#pragma mark - client delegate methods

- (void)addedUploadOperation:(LACamliUploadOperation *)op
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:[_operations count] inSection:1];

    @synchronized(_operations){
        [_operations addObject:op];
        [_table insertRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)finishedUploadOperation:(LACamliUploadOperation *)op
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:[_operations indexOfObject:op] inSection:1];

    @synchronized(_operations){
        [_operations removeObject:op];
        [_table deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)uploadProgress:(float)pct forOperation:(LACamliUploadOperation *)op
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:[_operations indexOfObject:op] inSection:1];
    UploadTaskCell *cell = (UploadTaskCell *)[_table cellForRowAtIndexPath:path];

    cell.progress.progress = pct;
}

#pragma mark - table view methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;

    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"statusCell" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"taskCell" forIndexPath:indexPath];

        LACamliUploadOperation *op = [_operations objectAtIndex:indexPath.row];

        [[(UploadTaskCell *)cell displayText] setText:[NSString stringWithFormat:@"%@",[op name]]];
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = @"";

    if (section == 0) {
        title = @"status";
    } else {
        title = @"uploads";
    }

    return title;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else {
        return [self.operations count];
    }
}

#pragma mark - other

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
