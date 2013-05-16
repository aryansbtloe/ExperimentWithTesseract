//
//  ViewController.m
//  TesseractSample
//
//  Created by Loïs Di Qual on 08/10/12.
//  Copyright (c) 2012 Loïs Di Qual. All rights reserved.
//

#import "ViewController.h"
#import "Tesseract.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "SSPhotoCropperViewController.h"
#import "ImageFilter.h"


#define MIN_IMAGE_NUMBER 0
#define MAX_IMAGE_NUMBER 1


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    currentImageUsed = 0;
    [NSThread detachNewThreadSelector:@selector(decodeAndDisplayImage) toTarget:self withObject:nil];
    
}

-(IBAction)decodeAndDisplayPreviousImage:(id)sender
{
    [pageNoInputTextField setEnabled:FALSE];
    [pageNoInputTextField setText:@"processing"];
    currentImageUsed--;
    
    if (currentImageUsed<MIN_IMAGE_NUMBER)
        currentImageUsed=MIN_IMAGE_NUMBER;
    
    [NSThread detachNewThreadSelector:@selector(decodeAndDisplayImage) toTarget:self withObject:nil];
    
}

-(IBAction)decodeAndDisplayNextImage:(id)sender
{
    [pageNoInputTextField setEnabled:FALSE];
    [pageNoInputTextField setText:@"processing"];
    currentImageUsed++;
    
    if (currentImageUsed>MAX_IMAGE_NUMBER)
        currentImageUsed=MAX_IMAGE_NUMBER;
    
    [NSThread detachNewThreadSelector:@selector(decodeAndDisplayImage) toTarget:self withObject:nil];
}

-(IBAction)reloadImage:(id)sender
{
    [pageNoInputTextField setEnabled:FALSE];
    
    int pageNo  = -1;
    
    if (pageNoInputTextField.text.length>0)
        pageNo = pageNoInputTextField.text.intValue;
    
    if (pageNo>0)
    {
        currentImageUsed = pageNo;
        
        if (currentImageUsed<MIN_IMAGE_NUMBER)
            currentImageUsed=MIN_IMAGE_NUMBER;
        
        if (currentImageUsed>MAX_IMAGE_NUMBER)
            currentImageUsed=MAX_IMAGE_NUMBER;
        
        [pageNoInputTextField setText:[[NSNumber numberWithInt:currentImageUsed] stringValue]];
    }
    else
        [pageNoInputTextField setText:[[NSNumber numberWithInt:currentImageUsed] stringValue]];
    
    [NSThread detachNewThreadSelector:@selector(decodeAndDisplayImage) toTarget:self withObject:nil];
}

-(IBAction)cropImage
{
    UIImage *photo = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",currentImageUsed]];
    SSPhotoCropperViewController *photoCropper =
    [[SSPhotoCropperViewController alloc] initWithPhoto:photo
                                               delegate:self
                                                 uiMode:SSPCUIModePresentedAsModalViewController
                                        showsInfoButton:YES];
    [photoCropper setMinZoomScale:1.0f];
    [photoCropper setMaxZoomScale:18.0f];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:photoCropper];
    [self presentModalViewController:nc animated:YES];
}

#pragma -
#pragma SSPhotoCropperDelegate Methods

- (void) photoCropper:(SSPhotoCropperViewController *)photoCropper
         didCropPhoto:(UIImage *)photo
{
    imageToDisplay = photo;
    [NSThread detachNewThreadSelector:@selector(decodeAndDisplayCroppedImage) toTarget:self withObject:nil];
    [photoCropper dismissModalViewControllerAnimated:YES];
}

- (void) photoCropperDidCancel:(SSPhotoCropperViewController *)photoCropper
{
    [photoCropper dismissModalViewControllerAnimated:YES];
}


-(void)decodeAndDisplayImage
{
    @autoreleasepool
    {
        Tesseract* tesseract       = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"chi_sim"];
        UIImage * imageToRecognise = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",currentImageUsed]];
        
        if (imageToRecognise)
        {
            if(optimiseImage.isOn)
                imageToRecognise = [self imageOptimisation:imageToRecognise];
            
            NSLog(@"\nimage height %f",imageToRecognise.size.height);
            NSLog(@"\nimage width %f",imageToRecognise.size.width);
            
            imageToDisplay = imageToRecognise;
            
            [tesseract setImage:imageToRecognise];
            [tesseract recognize];
            
            textToDisplay = [tesseract recognizedText];
            
            [self performSelectorOnMainThread:@selector(updateUI) withObject:self waitUntilDone:NO];
        }
    }
}

-(void)decodeAndDisplayCroppedImage
{
    @autoreleasepool
    {
        Tesseract* tesseract       = [[Tesseract alloc] initWithDataPath:@"tessdata" language:@"chi_sim"];
        UIImage* imageToRecognise  = imageToDisplay;
        
        if (imageToRecognise)
        {
            if(optimiseImage.isOn)
                imageToRecognise = [self imageOptimisation:imageToRecognise];
            
            NSLog(@"\nimage height %f",imageToRecognise.size.height);
            NSLog(@"\nimage width %f",imageToRecognise.size.width);
            
            imageToDisplay = imageToRecognise;
            
            [tesseract setImage:imageToRecognise];
            [tesseract recognize];
            
            textToDisplay = [tesseract recognizedText];
            
            [self performSelectorOnMainThread:@selector(updateUI) withObject:self waitUntilDone:NO];
        }
    }
}




-(void)updateUI
{
    [imageView setImage:imageToDisplay];
    [scrollView setContentMode:UIViewContentModeCenter];
    [imageView setFrame:CGRectMake(0,0,imageToDisplay.size.width,imageToDisplay.size.height)];
    [scrollView setContentSize:CGSizeMake(imageView.frame.size.width,imageView.frame.size.height)];
    [imageView setNeedsDisplay];
    
    [ocrDecodedOutputDisplay setText:[NSString stringWithFormat:@"\n\nRECOGNISED TEXT FOR IMAGE %@ is \n\n\n%@\n\n",[NSString stringWithFormat:@"%d.jpg",currentImageUsed],textToDisplay]];
    
    NSLog(@"ocrDecodedOutputDisplay text %@",ocrDecodedOutputDisplay.text);
    
    [pageNoInputTextField setText:[[NSNumber numberWithInt:currentImageUsed] stringValue]];
    [pageNoInputTextField setEnabled:TRUE];
}

-(UIImage*)imageOptimisation:(UIImage*)img
{
    
    if (twoBitBlackAndWhite.isOn)
    {
        ///////IMAGE OPTIMISTAION STEP : CONVERTING IMAGE TO  TWO BIT GRAYSCALE/////////////////////////////////////////
        img = [self convertImageTo2BitBlackAndWhite:img];
    }
    
    if (contrast.isOn)
    {
        ///////IMAGE OPTIMISTAION STEP : IMAGE CONSTRASTING///////////////////////////////////////////////////////////////
        img = [img contrast:-1];
    }
    
    if (scale.isOn)
    {
        ///////IMAGE OPTIMISTAION STEP : SCALIING TO THREE TIMES OF ORIGINAL RESOLUTION/////////////////////////////////
        img = [img scaleToSize:CGSizeMake(img.size.width*3,img.size.height*3)];
    }
    
    if (grayScale.isOn)
    {
        ///////IMAGE OPTIMISTAION STEP : CONVERTING COLOURED IMAGE TO GRAYSCALE/////////////////////////////////////////
        img = [self convertImageToGrayScale:img];
    }
    
    if (sharpening.isOn)
    {
        ///////IMAGE OPTIMISTAION STEP : IMAGE SHARPENING///////////////////////////////////////////////////////////////
        img = [img sharpen];
    }

    
    return img;
}

- (UIImage *)convertImageToGrayScale:(UIImage *)image
{
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
    CGContextDrawImage(context, imageRect, [image CGImage]);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, image.size.width, image.size.height),imageRef);
    CGContextRelease(context);
    CFRelease(imageRef);
    return newImage;
}

- (UIImage *)convertImageTo2BitBlackAndWhite:(UIImage *)image
{
    UIImage *originalImage = image;
    
    unsigned char *pixelBuffer = nil;
    
    pixelBuffer =  CFDataGetBytePtr(CGDataProviderCopyData(CGImageGetDataProvider([image CGImage])));
    
    size_t length = originalImage.size.width * originalImage.size.height * 4;
    CGFloat intensity;
    int bw;
    //50% threshold
    const CGFloat THRESHOLD = 0.8;
    for (int index = 0; index < length; index += 4)
    {
        intensity = (pixelBuffer[index] + pixelBuffer[index + 1] + pixelBuffer[index + 2]) / 3. / 255.;
        if (intensity > THRESHOLD)
        {
            bw = 255;
        }
        else
        {
            bw = 0;
        }
        pixelBuffer[index] = bw;
        
        
        pixelBuffer[index + 1] = bw;
        pixelBuffer[index + 2] = bw;
    }
    
    CGColorSpaceRef colorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapContext=CGBitmapContextCreate(pixelBuffer, originalImage.size.width, originalImage.size.height, 8, 4*originalImage.size.width, colorSpace,  kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault);
    CFRelease(colorSpace);
    free(pixelBuffer);
    CGImageRef cgImage=CGBitmapContextCreateImage(bitmapContext);
    CGContextRelease(bitmapContext);
    
    return [UIImage imageWithCGImage:cgImage];
}

-(UIImage*)sharpeningOfImage:(UIImage*)img
{
    return img;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self reloadImage:nil];
    return YES;
}
@end
