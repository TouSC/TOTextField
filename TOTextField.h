//
//  SCTextField.h
//  XStudio
//
//  Created by Tousan on 15/11/20.
//  Copyright (c) 2015年 Tousan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
@class TOTextField;

typedef enum {
    SCTextFieldClear,
    SCTextFieldPass,
    SCTextFieldFail
}SCTextFieldStatus;

@protocol TOTextFieldDelegate <NSObject>
@optional
- (void)textFieldDidChange:(TOTextField*)textField;
- (void)textFieldDidBeginEditing:(TOTextField*)textField;
- (void)textFieldDidEndEditing:(TOTextField*)textField;
- (BOOL)textFieldShouldReturn:(TOTextField *)textField;

@end

@interface TOTextField : UITextField <UITextFieldDelegate>

@property(nonatomic,assign)NSUInteger maxCount;

@property(nonatomic,assign)NSUInteger defaultGuessCount;
@property(nonatomic,strong)NSArray *defaultArray;

@property(nonatomic,assign)BOOL isTrimmingSpace;
@property(nonatomic,assign)BOOL isTrimmingBreakLine;

@property(nonatomic,strong)UIScrollView *scrollView;//必须在设置delegate之前设置
@property(nonatomic,assign)id<TOTextFieldDelegate>myDelegate;

+ (NSUInteger)lengthOfString:(NSString*)string;

@end
