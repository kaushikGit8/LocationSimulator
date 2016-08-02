//
//  ViewController.m
//  LocationTest
//
//  Created by PankajNeve on 05/08/15.
//  Copyright (c) 2015 Copyright (c) 2015 Cognizant Technology Solutions. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>

#define kFileName @"MyTrip.txt"
#define kGPXFileName @"MyTrip.gpx"
#define kMimeType @"application/plain"

#define kStoredRouteWidth 1.0
#define kActualRouteWidth 5.0

#define  kSEND_EMAIL_TITLE @"Send location data"
#define  kSEND_EMAIL_CANCELLED_MESSAGE @"Your email has been cancelled sucessfully."
#define  kSEND_EMAIL_SAVED_MESSAGE @"Your email has been saved sucessfully."
#define  kSEND_EMAIL_SENT_MESSAGE @"Your email has been sent sucessfully."
#define  kSEND_EMAIL_FAILED_MESSAGE @"When you send the mail has been an error : %@."
#define  kSEND_EMAIL_NOT_CONFIGURED @"The mail could not be sent - please check your e-mail settings."


@interface ViewController ()

@end

@implementation ViewController{
    
    BOOL isFirstLaunch;
    NSMutableArray *myLocations;
    NSMutableArray *storedLocations;
    NSFileManager *filemgr;
    NSUInteger storedLocationIndex;
    NSString *locationPath;
    NSTimer *simulationTimer;
    NSMutableString *gpxString;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [_btnStop setHidden:YES];
    [self.lblLocation setText:@"Location Details"];
    [self.progressIndicator stopAnimating];
    
    [self initAndConfigureMapKit];
    [self initAndConfigureLocationManager];
    
    filemgr = [NSFileManager defaultManager];
    
    locationPath = [self documentDirectoryPathForFileName:kFileName];
    if (![filemgr fileExistsAtPath: locationPath]){
        [[self btnExecuteStoredTrip] setHidden:YES];
        [[self btnSendEmail] setHidden:YES];
    }
    
    myLocations=[NSMutableArray new];
    storedLocations = [NSMutableArray new];
    storedLocationIndex=0;
    
    [self centerMap];
    
    gpxString = [NSMutableString new];
    [gpxString setString:@"<?xml version='1.0'?><gpx version='1.1' creator='GPXFileCreatorApp'>"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
   // NSLog(@"locationManager - didFailWithError: %@", error);
    UIAlertView *errorAlert = [[UIAlertView alloc]
                               initWithTitle:@"Error" message:@"Failed to Get Your Location!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [errorAlert show];
}


- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    //NSLog(@"Trip Location : \n");
    //NSLog(@"didUpdateToLocation %@ from %@", newLocation, oldLocation);
    
    [self.lblLocation setText:[NSString stringWithFormat:@"%@",newLocation]];
    if (newLocation != nil) {
        if (!isFirstLaunch) {
            [self performSelector:@selector(dropPin:) withObject:newLocation afterDelay:2];
            isFirstLaunch=YES;
        }
    }
    
    if ((newLocation.coordinate.latitude != oldLocation.coordinate.latitude) &&
        (newLocation.coordinate.longitude != oldLocation.coordinate.longitude))
    {
        [myLocations addObject:newLocation];
        
        [self drawRoute:myLocations];
        
    }
    
    
}


#pragma mark - MKMapViewDelegate

- (MKAnnotationView *) mapView: (MKMapView *) mapView viewForAnnotation: (id<MKAnnotation>) annotation {
    MKPinAnnotationView *pin = (MKPinAnnotationView *) [self.mapView dequeueReusableAnnotationViewWithIdentifier: @"myPin"];
    if (pin == nil) {
        pin = [[MKPinAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"myPin"];
    } else {
        pin.annotation = annotation;
    }
    pin.animatesDrop = YES;
    pin.draggable = YES;
    pin.highlighted = YES;
    pin.animatesDrop=YES;
    pin.canShowCallout = YES;
    
    return pin;
}

- (MKOverlayRenderer *)rendererForOverlay:(id <MKOverlay>)overlay{
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    renderer.strokeColor = [UIColor redColor];
    renderer.lineWidth = 2.0;
    return  renderer;
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay{
    
    MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
    UIColor *routeColor;
    CGFloat routeWidth;
    
    if (simulationTimer)
    {
        routeColor = [UIColor redColor];
        routeWidth = kStoredRouteWidth;
    }
    else
    {
        routeColor = [UIColor greenColor];
        routeWidth = kActualRouteWidth;
    }
    renderer.strokeColor = routeColor;
    renderer.lineWidth = routeWidth;
    
    return  renderer;
}


#pragma mark - MFMailComposeViewController Delegate
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    NSString *alertMsg;
    switch (result)
    {
        case MFMailComposeResultCancelled:
            alertMsg = kSEND_EMAIL_CANCELLED_MESSAGE;
            break;
        case MFMailComposeResultSaved:
            alertMsg = kSEND_EMAIL_SAVED_MESSAGE;
            break;
        case MFMailComposeResultSent:
            alertMsg = kSEND_EMAIL_SENT_MESSAGE;
            break;
        case MFMailComposeResultFailed:
            alertMsg = [NSString stringWithFormat:kSEND_EMAIL_FAILED_MESSAGE, [error localizedDescription]];
            break;
        default:
            break;
    }
    
    // dismiss mail composer
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kSEND_EMAIL_TITLE message:alertMsg delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

#pragma mark helper Methods

- (void)initAndConfigureMapKit {
    
    [self.mapView setDelegate:self];
}

- (void)initAndConfigureLocationManager {
    // Create location manager with filters set for battery efficiency.
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
}

- (NSString *)documentDirectoryPathForFileName:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

-(void)persistTheRoute:(NSArray*)locationsArray{
    
    if ([filemgr fileExistsAtPath: locationPath]){
        NSError *error;
        BOOL removeSuccess = [filemgr removeItemAtPath:locationPath error:&error];
        if (!removeSuccess) {
            // Error handling
        }else{
            //NSLog(@"File is deleted.");
        }
    }
    
    [NSKeyedArchiver archiveRootObject:locationsArray toFile:locationPath];
    
}

- (void)getLocationsFromSavedTrip {
    
    // Check if the file already exists
    if ([filemgr fileExistsAtPath: locationPath])
    {
        NSMutableArray *dataArray;
        dataArray = [NSKeyedUnarchiver
                     unarchiveObjectWithFile: locationPath];
        //NSLog(@"Locations array found ! %@",dataArray);
        [myLocations removeAllObjects];
        [myLocations addObjectsFromArray:dataArray];
    }
}

-(void) dropPin:(CLLocation*)location{
    
    
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = location.coordinate;
    point.title = @"My Current Location";
    
    [self.mapView addAnnotation:point];
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:MKCoordinateRegionMakeWithDistance(location.coordinate, 500, 500)];
    [_mapView setRegion:adjustedRegion animated:YES];
}

- (void)centerMap {
    //Pune coordinates : 18.5203° N, 73.8567° E
    CLLocationCoordinate2D startCoord = CLLocationCoordinate2DMake(18.5203, 73.8567);
    MKCoordinateRegion adjustedRegion = [self.mapView regionThatFits:MKCoordinateRegionMakeWithDistance(startCoord, 1500000, 1500000)];
    [self.mapView setRegion:adjustedRegion animated:YES];
}


- (void) drawRoute:(NSArray *) path
{
    if (!simulationTimer) {
        [[self mapView] removeOverlays:[[self mapView] overlays]];
    }
    
    NSInteger numberOfSteps = path.count;
    
    CLLocationCoordinate2D coordinates[numberOfSteps];
    for (NSInteger i = 0; i < numberOfSteps; i++) {
        CLLocation *location = (CLLocation *)[path objectAtIndex:i];
        CLLocationCoordinate2D coordinate = location.coordinate;
        
        coordinates[i] = coordinate;
    }
    
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:coordinates count:numberOfSteps];
    [[self mapView] addOverlay:polyLine];
}

-(void)emailSupport{
    
    NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
    NSString *model = [[UIDevice currentDevice] model];
    NSString *version = @"1.0";
    NSString *build = @"100";
    MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
    mailComposer.mailComposeDelegate = self;
    [mailComposer setToRecipients:[NSArray arrayWithObjects: @"pankaj.neve@cognizant.com",nil]];
    [mailComposer setSubject:[NSString stringWithFormat: @"My Trip attached at V%@ (build %@) Support",version,build]];
    NSString *supportText = [NSString stringWithFormat:@"Device: %@\niOS Version:%@\n\n",model,iOSVersion];
    supportText = [supportText stringByAppendingString: @"Please provide the details of your trip here, if required."];
    [mailComposer setMessageBody:supportText isHTML:NO];
    locationPath = [self documentDirectoryPathForFileName:kFileName];
    NSLog(@"Path : %@",locationPath);
    if ([filemgr fileExistsAtPath: locationPath]){
        //Read the file using NSData
         NSData *fileData = [NSData dataWithContentsOfFile:locationPath];
        
        // Add attachment for Object file.
        [mailComposer addAttachmentData:fileData mimeType:kMimeType fileName:kFileName];
    }
    NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/TripFile.gpx"];
    if ([filemgr fileExistsAtPath:docPath]) {
        
        NSData *fileData = [NSData dataWithContentsOfFile:docPath];
        
        // Add attachment for GPX file.
        [mailComposer addAttachmentData:fileData mimeType:kMimeType fileName:kGPXFileName];
    }
    [self presentViewController:mailComposer animated:YES completion:nil];
    
}

- (void)simulateStoredTrip {
    
    [self drawRoute:myLocations];
    
    simulationTimer = [ NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(iterateOverStoredTrip) userInfo:nil repeats:YES];
}

-(void)iterateOverStoredTrip {
   
    if (storedLocationIndex < myLocations.count) {
        //NSLog(@"Location : %@",((CLLocation *)[myLocations objectAtIndex:storedLocationIndex]));
        [self.lblLocation setText:[NSString stringWithFormat:@"%@",[myLocations objectAtIndex:storedLocationIndex]]];
        [storedLocations addObject:((CLLocation *)[myLocations objectAtIndex:storedLocationIndex])];
        
         NSLog(@"<wpt lat=\"%f\" lon=\"%f\"/>\n",((CLLocation *)[myLocations objectAtIndex:storedLocationIndex]).coordinate.latitude,((CLLocation *)[myLocations objectAtIndex:storedLocationIndex]).coordinate.longitude);
        NSString *string = [NSString stringWithFormat:@"<wpt lat=\"%f\" lon=\"%f\"/>",((CLLocation *)[myLocations objectAtIndex:storedLocationIndex]).coordinate.latitude,((CLLocation *)[myLocations objectAtIndex:storedLocationIndex]).coordinate.longitude];
        
        [gpxString appendString:string];
        storedLocationIndex++;
        
    }else{
        
        [self.progressIndicator stopAnimating];
   
        [[self btnStart] setHidden:NO];
        [[self btnSendEmail] setHidden:NO];
        
        // Drop Pin at Stop point.
        [self dropPin:(CLLocation*)[storedLocations lastObject]];
        
        [simulationTimer invalidate];
        simulationTimer  =  nil;
        
        
        [self drawRoute:myLocations];
        [self drawRoute:storedLocations];
        
        
        storedLocationIndex=0;
        [storedLocations removeAllObjects];
        NSString *docPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/TripFile.gpx"];
        NSLog(@"Path :: %@",docPath);
        [gpxString appendString:@"</gpx>"];
        [gpxString writeToFile:docPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        [gpxString setString:@"<?xml version='1.0'?><gpx version='1.1' creator='GPXFileCreatorApp'>"];
        return;
        
    }
    
    [self drawRoute:storedLocations];
}



#pragma mark Action Methods
- (IBAction)didStartSelected:(id)sender {
    //NSLog(@"Start tapped...");
    
    [storedLocations removeAllObjects];
    [myLocations removeAllObjects];
    [self.mapView removeAnnotations:[self.mapView annotations]];
    
    // Start updating location changes.
    [self.locationManager startUpdatingLocation];
    
    //enable/disable buttons
    [self.btnStart setHidden:YES];
    [self.btnStop setHidden:NO];
    [self.btnExecuteStoredTrip setHidden:YES];
    [self.btnSendEmail setHidden:YES];
    
    [self.mapView setShowsUserLocation:YES];

}

- (IBAction)didStopSelected:(id)sender {
   // NSLog(@"Stop tapped...");
    
    [self.mapView setShowsUserLocation:NO];

    
    // Stop updating location changes.
    [self.locationManager stopUpdatingLocation];
    [self dropPin:(CLLocation*)[myLocations lastObject]];
    
    //enable/disable buttons
    [self.btnStart setHidden:NO];
    [self.btnStop setHidden:YES];
    
    
    [self.lblLocation setText:@"Location Details"];
    
    //NSLog(@"Stored Locations Array :\n %@",myLocations);
   [self persistTheRoute:myLocations];
    if ([filemgr fileExistsAtPath: locationPath]){
        [self.btnExecuteStoredTrip setHidden:NO];
        [self.btnSendEmail setHidden:NO];
    }
   [myLocations removeAllObjects];
    
    isFirstLaunch = NO;
}

- (IBAction)didSelectExecuteStoredTrip:(id)sender {
    
    [self.mapView removeAnnotations:[self.mapView annotations]];
    //NSLog(@"Execute Stored Trip from saved file...");
    [self.progressIndicator startAnimating];
    [storedLocations removeAllObjects];
    [self getLocationsFromSavedTrip];
    [self dropPin:(CLLocation*)[myLocations firstObject]];
   
    [[self btnStart] setHidden:YES];
    [[self btnSendEmail] setHidden:YES];
    
    [self simulateStoredTrip];
    
}

- (IBAction)didSelectSendMail:(id)sender {
    
    if ([MFMailComposeViewController canSendMail]) {
        [self emailSupport];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:kSEND_EMAIL_TITLE message:kSEND_EMAIL_NOT_CONFIGURED delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [alert show];
    }
    
}

@end
