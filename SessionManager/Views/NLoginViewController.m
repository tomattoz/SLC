//
//  PSMLoginViewController.m
//
//  Created by Oleg Borovik on 12/11/14.
//  Copyright (c) 2021 Penn State. All rights reserved.
//
#import "NLoginViewController.h"

@interface NLoginViewController ()

@property (nonatomic) NSString *username;
@property (nonatomic) NSString *password;
@property (nonatomic) NSString *loginStatus;
@property (nonatomic) BOOL executingLogin;

@end

@implementation NLoginViewController

/**
 *  Setup UI elements
 */
- (void)awakeFromNib {
    loadingView = [NSView new];

    // Detect if user closes login window
    closeButton = [_loginWindow standardWindowButton:NSWindowCloseButton];
    [closeButton setTarget:self.delegate];
    [closeButton setAction:@selector(closeApp:)];
    
    [self.loginButton setAction:@selector(login:)];
    [self setTextColorForButton:self.loginButton color:[NSColor whiteColor]];
    NSButtonCell* bcell = self.loginButton.cell
    
    ;
    bcell.backgroundColor = [NSColor whiteColor];
    self.loginButton.wantsLayer = YES;
    
    // Setup 'need an account?' button
    [self.needAccountButton setAction:@selector(needAnAccount:)];
    [self setTextColorForButton:self.needAccountButton color:[NSColor whiteColor]];
    self.needAccountButton.wantsLayer = YES;

    // Email text field
    [self.usernameField setSelectable:YES];
    [self setCursorColorForField:self.usernameField color:[NSColor whiteColor]];
    //username.wantsLayer = YES;
    //username.layer.cornerRadius = 10;
    //username.layer.borderWidth = 1;
    //username.layer.borderColor = [NSColor whiteColor].CGColor;

    // Password text field
    [self.passwordField setSelectable:YES];
    [self setCursorColorForField:self.passwordField color:[NSColor whiteColor]];
    //password.wantsLayer = YES;
    //password.layer.cornerRadius = 10;
    //password.layer.borderWidth = 1;
    //password.layer.borderColor = [NSColor whiteColor].CGColor;
    
    // Progress indicator
    self.loginStatus = @"";
    self.executingLogin = NO;
    [_loginWindow makeKeyAndOrderFront:self];
    
    // Load in login settings from keychain if available
    [self getLoginInfoFromKeychain];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NSTextViewDidChangeSelectionNotification
                object:self.usernameField.stringValue //self.usernameField
                queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note){
                    NSLog(@"usernameField Text: %@", self.usernameField.stringValue);
                }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSTextViewDidChangeSelectionNotification
                object:self.passwordField.stringValue //self.usernameField
                queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *note){
                    NSLog(@"passwordField Text: %@", self.passwordField.stringValue);
                }];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(executingLogin:)
                                                 name:NSControlTextDidChangeNotification
                                               object:self.loginButton];
 
    //@weakify(self)
    // Handle error message changes
/*
    [[RACObserve(self, loginStatus) distinctUntilChanged]
        subscribeNext:^(NSString *statusMessage) {
            @strongify(self)
            self.loginStatusField.stringValue = statusMessage;
            self.loginStatusField.hidden = [statusMessage isEqualToString:@""];
        }];
    
    RAC(self.usernameField, stringValue) = RACObserve(self, username);
    RAC(self.passwordField, stringValue) = RACObserve(self, password);
    RAC(self, username) = self.usernameField.rac_textSignal;
    RAC(self, password) = self.passwordField.rac_textSignal;
    RAC(self.loginButton, enabled) = [RACObserve(self, executingLogin) not];
 */
}

- (void)getLoginInfoFromKeychain {
    // Retrieve login credentials from Keychain
    NSString *bundleName = [[NSBundle mainBundle] bundleIdentifier];
    NSString *keychainUsername = @"KEYUSERNAME"; //[SAMKeychain passwordForService:bundleName account:FRDMKeychainUsernameKey];
    NSString *keychainPassword = @"KEYPASSW"; //[SAMKeychain passwordForService:bundleName account:FRDMKeychainPasswordKey];
    if (keychainUsername) {
        self.username = keychainUsername;
        if (keychainPassword) {
            self.password = keychainPassword;
        } else {
            self.password = @"";
        }
    } else {
        self.username = @"";
        self.password = @"";
    }
}

- (void)saveLoginInfoToKeychainWithUsername:(NSString *)username password:(NSString *)password {
    NSString *bundleName = [[NSBundle mainBundle] bundleIdentifier];
    //[SAMKeychain setPassword:username forService:bundleName account:FRDMKeychainUsernameKey];
    //[SAMKeychain setPassword:password forService:bundleName account:FRDMKeychainPasswordKey];
}

- (void)clearLoginInfoFromKeychain {
    NSString *bundleName = [[NSBundle mainBundle] bundleIdentifier];
    //[SAMKeychain deletePasswordForService:bundleName account:FRDMKeychainUsernameKey];
    //[SAMKeychain deletePasswordForService:bundleName account:FRDMKeychainPasswordKey];
}

- (void)loginWithUsername:(NSString *)username password:(NSString *)password registerUser:(BOOL)registerUser {
    username = @"USER" ; //[[ServerController sharedInstance] setServersWithEmail:username];
    
    if (registerUser) {
        self.loginStatus = @"registering new user...";
    } else {
        self.loginStatus = @"signing in...";
    }
    // Lock view to prevent user from changing things during the login process
    self.executingLogin = YES;
    
        [self.loginWindow makeKeyAndOrderFront:self];
        [self.delegate requireLogin];
}

/**
 *  Handle action of user clicking the login button
 *
 *  @param sender Sender of action
 */
- (IBAction)login:(id)sender {
    if (![self validateEmail:self.username]) {
        self.loginStatus = @"email is invalid";
    } else if ([self.password isEqualToString:@""]) {
        self.loginStatus = @"password cannot be blank";
    } else {
        self.loginButton.enabled = NO;
        self.loginStatus = @"";
        [self.window update];
        [self loginWithUsername:self.username password:self.password registerUser:NO];
    }
}

/**
 *  Tests if email address is valid, in a very loose sense
 *
 *  @param email Email address to check
 *
 *  @return YES if email is valid
 */
- (BOOL)validateEmail:(NSString *)email {
    NSString *emailRegex = @".+@.+\\..{2,}";       // Really loose filter
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

/**
 *  Handle "need an account?" button click
 *
 *  @param sender Sender of action
 */
- (IBAction)needAnAccount:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.psu.edu/"]];
}

/**
 *  Set the foreground color of button
 *
 *  @param button    Button to modify
 *  @param textColor Color to use for foreground text
 */
- (void)setTextColorForButton:(NSButton *)button color:(NSColor *)textColor {
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[button attributedTitle]];
    NSRange range = NSMakeRange(0, [attrTitle length]);
    [attrTitle addAttribute:NSForegroundColorAttributeName value:textColor range:range];
    [attrTitle fixAttributesInRange:range];
    [button setAttributedTitle:attrTitle];
}

/**
 *  Set the cursor color of text field
 *
 *  @param field     Text field of modify
 *  @param textColor Color to use for cursor
 */
- (void)setCursorColorForField:(NSTextField *)field color:(NSColor *)textColor {
    NSTextView *fieldEditor = (NSTextView *)[field.window fieldEditor:YES forObject:field];
    fieldEditor.insertionPointColor = textColor;
}

@end
