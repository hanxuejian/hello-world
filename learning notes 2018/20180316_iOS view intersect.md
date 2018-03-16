### 判断视图是否相交以及是否被键盘遮盖
```
@interface UIView (Util)

///返回视图是否相交，若相交，offset 的值表示避免相交需要的位移
- (BOOL)isCoveredByView:(UIView *)view offset:(CGFloat *)offset;

///返回视图是否被键盘遮盖，若是，offset 的值表示视图要避免遮盖的位移量
- (BOOL)isCoveredByBoard:(CGRect)keyboardRect offset:(CGFloat *)offset;

@end
```

```

@implementation UIView (Util)

#pragma mark 判断当前视图是否被其他视图遮盖
- (BOOL)isCoveredByView:(UIView *)view offset:(CGFloat *)offset {
    if (!self || !view) {
        return NO;
    }
    if (![self superview]) {
        return NO;
    }
    if (self.hidden || view.hidden) {
        return NO;
    }
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    
    CGRect viewRect;
    if([view isKindOfClass:[UIWindow class]]){
        viewRect = [(UIWindow*)view convertRect:view.frame toWindow:keyWindow];
    }else {
        viewRect = [view.superview convertRect:view.frame toView:keyWindow];
    }
    
    CGRect rect = [self.superview convertRect:self.frame toView:keyWindow];
    if (CGRectIsEmpty(rect) || CGRectIsNull(rect) || CGSizeEqualToSize(rect.size, CGSizeZero)) {
        return NO;
    }
    CGFloat heightOfCovered = viewRect.origin.y - rect.origin.y - rect.size.height;
    heightOfCovered = heightOfCovered > -viewRect.size.height ? heightOfCovered : -viewRect.size.height;
    
    *offset = heightOfCovered;
    return CGRectIntersectsRect(rect, viewRect);
    
}

#pragma mark 判断当前视图是否被键盘遮盖
- (BOOL)isCoveredByBoard:(CGRect)keyboardRect offset:(CGFloat *)offset {
    if (!self) {
        return NO;
    }
    if (![self superview]) {
        return NO;
    }
    if (self.hidden) {
        return NO;
    }
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    NSArray *windows = [[UIApplication sharedApplication] windows];
    UIWindow *keyboardWindow;
    for (id window in windows) {
        
        NSString *keyboardWindowString = NSStringFromClass([window class]);
        if ([keyboardWindowString isEqualToString:@"UITextEffectsWindow"]) {
            keyboardWindow = window;
            break;
        }
    }
    if (keyboardWindow == nil) return NO;
    
    keyboardRect = [keyboardWindow convertRect:keyboardRect toWindow:keyWindow];
    CGRect rect = [self.superview convertRect:self.frame toView:keyWindow];
    if (CGRectIsEmpty(rect) || CGRectIsNull(rect) || CGSizeEqualToSize(rect.size, CGSizeZero)) {
        return NO;
    }
    CGFloat heightOfCovered = keyboardRect.origin.y - rect.origin.y - rect.size.height;
    heightOfCovered = heightOfCovered > -keyboardRect.size.height ? heightOfCovered : -keyboardRect.size.height;
    
    *offset = heightOfCovered;
    return CGRectIntersectsRect(rect, keyboardRect);
}

@end
```

```
#pragma mark - 键盘显示
- (void)keyboardWillShow:(NSNotification *)notification{
    if ([self.textField isFirstResponder]) {
        CGRect keyboardFrame = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        
        CGFloat offset;
        if ([self.textField isCoveredByBoard:keyboardFrame offset:&offset]){
            CGRect rect = self.textField.frame;
            rect.origin.y += offset;
            self.textField.frame = rect;
        }
    }
}
```