//
//  SCTextField.m
//  XStudio
//
//  Created by Tousan on 15/11/20.
//  Copyright (c) 2015年 Tousan. All rights reserved.
//

#import "TOTextField.h"

@implementation TOTextField
{
    NSString *preText;
    NSString *text;
    CGFloat off_y;
}

- (id)init;
{
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _maxCount = 100;
        self.delegate = self;
        self.minimumFontSize = 14;
        self.adjustsFontSizeToFitWidth = YES;
        [self addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventAllEditingEvents];
    }
    return self;
}

static const char isObservingKey = '\00';
static const char contentHeightKey = '\01';
static const char scrollViewKey = '\02';
- (void)setMyDelegate:(id<TOTextFieldDelegate>)myDelegate;
{
    _myDelegate = myDelegate;
    class_addMethod([(UIViewController*)_myDelegate class], @selector(touchesBegan:withEvent:), (IMP)touchBegan, "v:@@");
    BOOL isObserving = [objc_getAssociatedObject(_myDelegate, &isObservingKey) boolValue];
    if (!isObserving)
    {
        CGFloat contentHeight = _scrollView.contentSize.height;
        objc_setAssociatedObject(_myDelegate, &isObservingKey, @(YES), OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(_myDelegate, &contentHeightKey, @(contentHeight), OBJC_ASSOCIATION_RETAIN);
        objc_setAssociatedObject(_myDelegate, &scrollViewKey, _scrollView, OBJC_ASSOCIATION_RETAIN);
        [[NSNotificationCenter defaultCenter]addObserver:_myDelegate selector:@selector(hideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
        class_addMethod([(UIViewController*)_myDelegate class], @selector(hideKeyboard:), (IMP)hideKeyboard, "v:@");
    }
}

- (void)hideKeyboard:(NSNotification*)notification;
{
    //消除警告用，不会调用
}

static const char isContentChanged = '\03';

void touchBegan(id self,IMP _cmd,NSSet *touches,UIEvent *event)
{
    [[(UIViewController*)self view] endEditing:YES];
}

- (void)layoutSubviews;
{
    [super layoutSubviews];
    [self layoutIfNeeded];
}

- (void)textFieldDidChange:(UITextField*)textField;
{
    NSUInteger length = [TOTextField lengthOfString:textField.text];
    text = textField.text;
    if (length>_maxCount)
    {
        do{
            text = [text substringToIndex:text.length-1];
        }while ([TOTextField lengthOfString:text]>_maxCount);
        textField.text = text;
    }
    preText = textField.text;
    if (_myDelegate&&[_myDelegate respondsToSelector:@selector(textFieldDidChange:)])
    {
        [_myDelegate textFieldDidChange:self];
    }
}

+ (NSUInteger)lengthOfString:(NSString*)string;
{
    int length = 0;
    char *p = (char *)[string cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i = 0; i < [string lengthOfBytesUsingEncoding:NSUnicodeStringEncoding]; i++) {
        if (*p)
        {
            p++;
            length++;
        }
        else
        {
            p++;
        }
    }
    return length;
}

#pragma mark TextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField;
{
    if (_myDelegate&&[_myDelegate respondsToSelector:@selector(textFieldDidBeginEditing:)])
    {
        [_myDelegate textFieldDidBeginEditing:self];
    }
    
    CGRect rect = [[(UIViewController*)_myDelegate view] convertRect:self.frame fromView:self.superview];
    CGRect inrect = [_scrollView convertRect:self.frame fromView:self.superview];
    CGFloat bottom = rect.origin.y+rect.size.height;
    CGFloat top = [UIScreen mainScreen].bounds.size.height-290;
    
    if (_scrollView)
    {
        BOOL isChanged = [objc_getAssociatedObject(_scrollView, &isContentChanged) boolValue];
        if (!isChanged)
        {
            objc_setAssociatedObject(_scrollView, &isContentChanged, @(YES), OBJC_ASSOCIATION_RETAIN);
        }
        if (bottom<top)
        {
            return;
        }
        [UIView animateWithDuration:0.3 animations:^{
            [_scrollView setContentOffset:CGPointMake(0, 290-([UIScreen mainScreen].bounds.size.height-rect.origin.y-rect.size.height))];
        }];
    }
    else
    {
        if (bottom<top)
        {
            return;
        }
        [UIView animateWithDuration:0.3 animations:^{
            UIView *superView = [(UIViewController*)_myDelegate view];
            superView.frame = CGRectMake(superView.frame.origin.x, -(bottom-top)-20, superView.frame.size.width, superView.frame.size.height);
        }];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField;
{
    if (_myDelegate&&[_myDelegate respondsToSelector:@selector(textFieldDidEndEditing:)])
    {
        [_myDelegate textFieldDidEndEditing:self];
    }
}

void hideKeyboard(id self,IMP _cmd,NSNotification *notification)
{
    UIScrollView *scrollView = objc_getAssociatedObject(self, &scrollViewKey);
    if (scrollView)
    {
        objc_setAssociatedObject(scrollView, &isContentChanged, @(NO), OBJC_ASSOCIATION_RETAIN);
        if (scrollView.contentOffset.y>0)
        {
            [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        }
    }
    else
    {
        [UIView animateWithDuration:0.3 animations:^{
            UIView *superView = [(UIViewController*)self view];
            superView.frame = CGRectMake(superView.frame.origin.x, 0, superView.frame.size.width, superView.frame.size.height);
        }];
    }
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if ([string isEqualToString:@""])
    {
        return YES;
    }
    NSMutableString *text_String = [[NSMutableString alloc]initWithString:textField.text];
    [text_String deleteCharactersInRange:range];
    [text_String insertString:string atIndex:range.location];
    if (text_String.length>_defaultGuessCount)
    {
        NSString *behind = [self matchString:text_String];
        if (behind)
        {
            [text_String appendString:behind];
            textField.text = text_String;
            UITextPosition *endDocument = textField.endOfDocument;
            UITextPosition *end = [textField positionFromPosition:endDocument offset:0];
            UITextPosition *start = [textField positionFromPosition:end offset:-behind.length];
            textField.selectedTextRange = [textField textRangeFromPosition:start toPosition:end];
            return NO;
        }
        else
        {
            return YES;
        }
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    if (_myDelegate&&[_myDelegate respondsToSelector:@selector(textFieldShouldReturn:)])
    {
        [_myDelegate textFieldShouldReturn:self];
    }
    return YES;
}

-(NSString *)matchString:(NSString *)head
{
    for (int i=0;i<[_defaultArray count];i++)
    {
        NSString *string = _defaultArray[i];
        if ([string hasPrefix:head])
        {
            return [string substringFromIndex:head.length];
        }
    }
    return nil;
}

@end
