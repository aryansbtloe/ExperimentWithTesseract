//
//  ViewController.h
//  TesseractSample
//
//  Created by Loïs Di Qual on 08/10/12.
//  Copyright (c) 2012 Loïs Di Qual. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSPhotoCropperViewController.h"

@interface ViewController : UIViewController<SSPhotoCropperDelegate>
{
    IBOutlet UITextView   * ocrDecodedOutputDisplay;
    IBOutlet UIScrollView * scrollView;
    IBOutlet UIImageView  * imageView;
    NSInteger               currentImageUsed;
    IBOutlet UISwitch     * optimiseImage;
    IBOutlet UISwitch     * grayScale;
    IBOutlet UISwitch     * twoBitBlackAndWhite;
    IBOutlet UISwitch     * scale;
    IBOutlet UISwitch     * sharpening;
    IBOutlet UISwitch     * contrast;
    IBOutlet UITextField  * pageNoInputTextField;
    UIImage               * imageToDisplay;
    NSString              * textToDisplay;
    
}

-(IBAction)decodeAndDisplayPreviousImage:(id)sender;
-(IBAction)decodeAndDisplayNextImage:(id)sender;
-(IBAction)reloadImage:(id)sender;
-(IBAction)cropImage;

@end


@interface UIImage (scale)

-(UIImage*)scaleToSize:(CGSize)size;

@end

@implementation UIImage (scale)

-(UIImage*)scaleToSize:(CGSize)size
{
	UIGraphicsBeginImageContext(size);
	[self drawInRect:CGRectMake(0, 0, size.width, size.height)];
	UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return scaledImage;
}

@end