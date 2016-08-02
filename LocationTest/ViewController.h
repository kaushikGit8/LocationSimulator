//
//  ViewController.h
//  LocationTest
//
//  Created by PankajNeve on 05/08/15.
//  Copyright (c) 2015 T-Systems International GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MessageUI/MessageUI.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate, MKMapViewDelegate, MFMailComposeViewControllerDelegate>
{
    
}

@property (nonatomic, retain) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UIButton *btnStart;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIButton *btnExecuteStoredTrip;
@property (weak, nonatomic) IBOutlet UILabel *lblLocation;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (weak, nonatomic) IBOutlet UIButton *btnSendEmail;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *progressIndicator;


@end

