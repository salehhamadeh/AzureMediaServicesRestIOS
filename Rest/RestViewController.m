//
//  RestViewController.m
//  Rest
//
//  Created by Saleh Hamadeh on 5/22/14.
//  Copyright (c) 2014 Spring. All rights reserved.
//

#import "RestViewController.h"

@interface RestViewController ()

@end

@implementation RestViewController

- (NSString *)getAPIEndpointURL:(NSString *)endpoint
{
    //Specific to account
    //saleh account
    //NSString *apiUrl = @"https://wamsbluclus001rest-hs.cloudapp.net/api";
    
    NSString *apiVersionQueryString = [NSString  stringWithFormat:@"api-version=%@", self.apiVersion];
    return [NSString stringWithFormat:@"%@/%@?%@", self.apiUrl, endpoint, apiVersionQueryString];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Get the access token
    
    //saleh
    //self.accessToken = [self getAccessToken:@"tftestmediaservice"
    //                             accountKey:@"o0dHQmypilrfeIIlnBylVhB+KuRoq189PurrZ25icyU="];
    
    //tripfilesQA
    self.accessToken = [self getAccessToken:@"tripfilesqa2"
                                 accountKey:@"0uXuWRXKVX23EUhV8LT5ZDPT/uM6JwIfIrCJJJCAWk0="];
    
    self.apiUrl = @"https://wamsbayclus001rest-hs.cloudapp.net/api";
    self.apiVersion = @"2.6";
    
    
    /*self.accessToken = @"http%3a%2f%2fschemas.xmlsoap.org%2fws%2f2005%2f05%2fidentity%2fclaims%2fnameidentifier=tftestmediaservice&urn%3aSubscriptionId=73a37cf8-3c3d-45c0-8442-6d825b799bb5&http%3a%2f%2fschemas.microsoft.com%2faccesscontrolservice%2f2010%2f07%2fclaims%2fidentityprovider=https%3a%2f%2fwamsprodglobal001acs.accesscontrol.windows.net%2f&Audience=urn%3aWindowsAzureMediaServices&ExpiresOn=1401329690&Issuer=https%3a%2f%2fwamsprodglobal001acs.accesscontrol.windows.net %2f&HMACSHA256=tygFBbqNhfCL6zcBxm1r6xDHolcioliQYtKa0NbnY6I%3d";*/
}

/**
 * Gets an access token for the Azure Media Services account specified by accountName
 * @param accountName The name of the Azure Media Services account
 * @param accountKey The primary key of the Azure Media Services account
 * @return The access token
 *
 */
- (NSString *)getAccessToken:(NSString *)accountName accountKey: (NSString *)accountKey
{
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://wamsprodglobal001acs.accesscontrol.windows.net/v2/OAuth2-13"]];
    
    // Specify that it will be a POST request
    [request setHTTPMethod:@"POST"];
    
    // This is how we set header fields
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    // Convert your data and set your request's HTTPBody property
    NSString *stringData = [NSString stringWithFormat:@"grant_type=client_credentials&client_id=%@&client_secret=%@&scope=urn%%3aWindowsAzureMediaServices", accountName, [self urlEncode:accountKey]];
    
    NSData *requestBodyData = [stringData dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestBodyData;
    
    //Make the request
    NSURLResponse * response = nil;
    NSError * error = nil;
    
    NSData * data = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    if (error != nil) {
        return @"ERROR: Connection failed";
    }
    
    NSDictionary* jsonData = [NSJSONSerialization
                          JSONObjectWithData:data
                          options:kNilOptions
                          error:&error];
    if (error != nil) {
        return @"ERROR: Cannot parse response";
    }
    
    NSString *accessToken = [jsonData objectForKey:@"access_token"];
    
    return accessToken;
}

/**
 * Creates an asset on Azure Media Services
 * @param createAsset The name of the asset you want to create
 * @param accessToken The access token for authentication
 * @return ID of the created asset
 *
*/
- (NSString *)createAsset:(NSString *)assetName accessToken:(NSString *)accessToken
{
    NSError *error;
    
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self getAPIEndpointURL:@"Assets"]]];
    
    // Specify that it will be a POST request
    [request setHTTPMethod:@"POST"];
    
    // Set headers "Content-Type: application/json; charset=utf-8" and "Accept: application/json"
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    // Add the authorization token to the header
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
    
    // Convert your data and set your request's HTTPBody property
    //build an info object and convert to json
    NSDictionary* requestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                          assetName,
                          @"Name",
                          nil];
    
    //Convert dictionary to data
    NSData* requestJsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                              options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Generating JSON for request data");;
        return nil;
    }
    
    request.HTTPBody = requestJsonData;
    
    //Send the request
    NSURLResponse * response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                          returningResponse:&response
                                                      error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Connection failed");
        return nil;
    }
    
    NSDictionary *responseJson = [NSJSONSerialization
                          JSONObjectWithData:responseData
                          options:kNilOptions
                          error:&error];
    if (error != nil) {
        NSLog(responseData);
        NSLog(@"ERROR: Cannot parse response JSON");
        return nil;
    }
    
    NSString *assetId = [responseJson objectForKey:@"Id"];
    return assetId;
}

/**
 * Creates an asset on Azure Media Services
 * @param assetId The ID of the asset
 * @param accessToken The access token for authentication
 * @return HTTP Status code returned in response
 *
 */
- (NSInteger)createAssetFile:(NSString *) assetId accessToken: (NSString *) accessToken
{
    NSError *error;
    
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: [NSString stringWithFormat:@"%@&assetid='%@'", [self getAPIEndpointURL:@"CreateFileInfos"], [self urlEncode:assetId]]]];
    
    // Specify that it will be a GET request
    [request setHTTPMethod:@"GET"];
    
    // Set headers "Content-Type: application/json; charset=utf-8" and "Accept: application/json"
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    // Add the authorization token to the header
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
    
    //Send the request
    NSHTTPURLResponse * response = nil;
    [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response
                                      error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Connection failed");
        return -1;
    }
    
    return [response statusCode];

}

- (NSString *)createAccessPolicy:(NSString *) policyName durationInMinutes: (NSString *)durationInMinutes permissions:(NSNumber *)permissions accessToken:(NSString *)accessToken
{
    NSError *error;
    
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self getAPIEndpointURL:@"AccessPolicies"]]];
    
    // Specify that it will be a POST request
    [request setHTTPMethod:@"POST"];
    
    // Set headers "Content-Type: application/json; charset=utf-8" and "Accept: application/json"
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    // Add the authorization token to the header
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
    
    // Convert your data and set your request's HTTPBody property
    //build an info object and convert to json
    NSDictionary* requestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       policyName,
                                       @"Name",
                                       durationInMinutes,
                                       @"DurationInMinutes",
                                       permissions,
                                       @"Permissions",
                                       nil];
    
    //Convert dictionary to data
    NSData* requestJsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                              options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Generating JSON for request data");
        return nil;
    }
    
    request.HTTPBody = requestJsonData;
    
    //Send the request
    NSURLResponse * response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Connection failed");
        return nil;
    }
    
    NSDictionary *responseJson = [NSJSONSerialization
                                  JSONObjectWithData:responseData
                                  options:kNilOptions
                                  error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Cannot parse response JSON");
        return nil;
    }
    
    NSString *accessPolicyId = [responseJson objectForKey:@"Id"];
    return accessPolicyId;
}

- (NSDictionary *)createLocator:(NSString *) assetId accessPolicyId: (NSString *)accessPolicyId startTime:(NSString *)startTime type: (NSNumber *)locatorType accessToken:(NSString *)accessToken
{
    NSError *error;
    
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self getAPIEndpointURL:@"Locators"]]];
    
    // Specify that it will be a POST request
    [request setHTTPMethod:@"POST"];
    
    // Set headers "Content-Type: application/json; charset=utf-8" and "Accept: application/json"
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    // Add the authorization token to the header
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
    
    // Convert your data and set your request's HTTPBody property
    //build an info object and convert to json
    NSDictionary* requestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       accessPolicyId,
                                       @"AccessPolicyId",
                                       assetId,
                                       @"AssetId",
                                       startTime,
                                       @"StartTime",
                                       locatorType,
                                       @"Type",
                                       nil];
    
    //Convert dictionary to data
    NSData* requestJsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                              options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Generating JSON for request data");
        return nil;
    }
    
    request.HTTPBody = requestJsonData;
    
    //Send the request
    NSURLResponse * response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Connection failed");
        return nil;
    }
    
    NSDictionary *responseJson = [NSJSONSerialization
                                  JSONObjectWithData:responseData
                                  options:kNilOptions
                                  error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Cannot parse response JSON");
        return nil;
    }
    
    return responseJson;
}

/**
 * Uploads a file to an Azure Storage Services blob specified by blobUrl
 * @param blobUrl The url of the blob. Function will issue an HTTP PUT to this URL
 * @param fileName The name of the file to be stored in Azure Storage Service blog
 * @param fileData The file's data
 * @return statusCode of the HTTP response
 *
 */
- (NSInteger)uploadFileToBlob:(NSString *) blobUrl fileData: (NSData *)fileData accessToken:(NSString *)accessToken
{
    NSError *error;
    
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:blobUrl]];
    
    // Specify that it will be a POST request
    [request setHTTPMethod:@"PUT"];
    
    // Set headers "Content-Type: application/octet-stream"
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%u", fileData.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"BlockBlob" forHTTPHeaderField:@"x-ms-blob-type"];
    
    // Add the authorization token to the header
    //[request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
    
    request.HTTPBody = fileData;
    
    //Send the request
    NSHTTPURLResponse * response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Connection to blob failed");
        return nil;
    }

    return [response statusCode];
}

/**
 * Returns the Media Processors
 * @param accessToken The access token for authentication
 * @return An array of dictionaries describing the Media Processors
 *
 */
- (NSArray *)getMediaProcessors:(NSString *) accessToken
{
    NSError *error;
    
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: [self getAPIEndpointURL:@"MediaProcessors"]]];
    
    // Specify that it will be a GET request
    [request setHTTPMethod:@"GET"];
    
    // Set headers "Content-Type: application/json; charset=utf-8" and "Accept: application/json"
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    // Add the authorization token to the header
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
    
    //Send the request
    NSHTTPURLResponse * response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                          returningResponse:&response
                                      error:&error];
    
    if (error != nil) {
        NSLog(@"ERROR: Connection failed");
        return nil;
    }
    
    NSDictionary *responseJson = [NSJSONSerialization
                                  JSONObjectWithData:responseData
                                  options:kNilOptions
                                  error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Cannot parse response JSON");
        return nil;
    }
    
    NSArray *mediaProcessors = [responseJson objectForKey:@"value"];

    return mediaProcessors;
    
}

//CAUTION: THIS METHOD CAN ONLY BE USED WITH MEDIA SERVICES < 2.5. THE NEWER API RELEASE INCLUDES NOTIFICATIONS FOR JOBS
- (NSDictionary *)startEncodingJob:(NSString *)jobName assetId:(NSString *) assetId mediaProcessorId: (NSString *)mediaProcessorId encodingPreset:(NSString *)encodingPreset accessToken:(NSString *)accessToken
{
    NSError *error;
    
    // Create the request.
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[self getAPIEndpointURL:@"Jobs"]]];
    
    // Specify that it will be a POST request
    [request setHTTPMethod:@"POST"];
    
    // Set headers "Content-Type: application/json; charset=utf-8" and "Accept: application/json"
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:self.apiVersion forHTTPHeaderField:@"x-ms-version"];
    
    // Add the authorization token to the header
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
    
    // Convert your data and set your request's HTTPBody property
    //build an info object and convert to json
    NSString *urlEncodedAssetId = [self urlEncode:assetId];
    NSString *inputMediaAssetUrl = [NSString stringWithFormat:@"%@/Assets('%@')", self.apiUrl, urlEncodedAssetId];
    NSArray *inputMediaAssets = [NSArray arrayWithObjects:
                                 [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                     inputMediaAssetUrl,
                                     @"uri"
                                     , nil],
                                    @"__metadata",
                                    nil],
                                 nil];
    NSArray *tasks = [NSArray arrayWithObjects:
                      [NSDictionary dictionaryWithObjectsAndKeys:
                       encodingPreset,
                       @"Configuration",
                       mediaProcessorId,
                       @"MediaProcessorId",
                       @"<taskBody><inputAsset>JobInputAsset(0)</inputAsset><outputAsset>JobOutputAsset(0)</outputAsset></taskBody>",
                       @"TaskBody",
                       nil],
                      nil];
    NSDictionary* requestDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                       jobName,
                                       @"Name",
                                       inputMediaAssets,
                                       @"InputMediaAssets",
                                       tasks,
                                       @"Tasks",
                                       nil];
    NSLog(@"Job request: %@", requestDictionary);
    //Convert dictionary to data
    NSData* requestJsonData = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                              options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Generating JSON for request data");
        return nil;
    }
    
    request.HTTPBody = requestJsonData;
    NSLog(@"Request JSON data: %@", [NSString stringWithUTF8String:[requestJsonData bytes]]);
    
    //Send the request
    NSURLResponse * response = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Connection failed");
        return nil;
    }
    
    NSDictionary *responseJson = [NSJSONSerialization
                                  JSONObjectWithData:responseData
                                  options:kNilOptions
                                  error:&error];
    if (error != nil) {
        NSLog(@"ERROR: Cannot parse response JSON");
        return nil;
    }
    
    return responseJson;
}

- (void)uploadVideoToAzure
{
    NSString *messages = @"";
    //Phase 1: Ingestion
    //Create asset
    NSString *assetId = [self createAsset:@"MadeInIOS"
          accessToken:self.accessToken];
    if (assetId == nil) {
        return;
    }
    //messages = [NSString stringWithFormat:@"%@%n%@", messages, @"Asset created."];
    
    
    

    //Create AccessPolicy with write permissions
    NSString *accessPolicyId = [self createAccessPolicy:@"My Access Policy"
                                      durationInMinutes:@"300"
                                            permissions:[NSNumber numberWithInt:2]
                                            accessToken:self.accessToken];
    
    //Create Locator with an upload URL to use when uploading the video
    //Set the locator's start time to 5 minutes before current time. This is needed, according to the API reference, for us to use to locator immediately.
    
    
    
    NSDate *beforeFiveMinutes = [[NSDate alloc] initWithTimeIntervalSinceNow:-5*60];
    NSDateFormatter *DateFormatter=[[NSDateFormatter alloc] init];
    [DateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSString *startTime = [NSString stringWithFormat:@"%@",[DateFormatter stringFromDate:beforeFiveMinutes]];
    
    //Create the locator
    NSDictionary *locatorResponse = [self createLocator:assetId
                                         accessPolicyId:accessPolicyId
                                              startTime:startTime
                                                   type:[NSNumber numberWithInt:1] //Type 1 means SAS URL (downloading only no streaming). Only used with unencoded asset
                                            accessToken:self.accessToken];
    
    //Upload video to storage
    //NOTE: This method works for files < 64MB. For files > 64MB, we need to upload in chunks. See Azure Storage REST API for
    // more info.
    //Gets the blob's directory from the Locator's path
    NSString *blobDirectoryPath = [locatorResponse objectForKey:@"Path"];
    NSURL *blobUrl = [NSURL URLWithString:blobDirectoryPath];   //Create an NSURL from the URL String
    NSString *fileName = @"sample.wmv";                         //Initialize the filename
    blobUrl = [blobUrl URLByAppendingPathComponent:fileName];   //Add the file name to the end of the url before the query parameters
    NSString *blobUrlString = [blobUrl absoluteString];         //Convert the URL back to an NSString
    
    //Use the sample video from videos.bundle for the demo
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"videos" ofType:@"bundle"];
    NSString *videoName = [[NSBundle bundleWithPath:bundlePath] pathForResource:@"IMG_0026" ofType:@"MOV"];
    NSData *videoData = [NSData dataWithContentsOfFile:videoName];
    
    NSInteger uploadStatusCode = [self uploadFileToBlob:blobUrlString
                                               fileData:videoData
                                            accessToken:self.accessToken];
    if (uploadStatusCode != 201) {
        NSLog(@"ERROR: Upload response code: %d", uploadStatusCode);
    }
    
    
    //messages = [NSString stringWithFormat:@"%@%n%@", messages, @"Video uploaded to Azure."];
    
    //TODO: Delete upload Locator from Azure (optional)
    
    //Create the AssetFile, which is used to generate the file's metadata
    
    NSInteger createAssetFileStatusCode = [self createAssetFile:assetId accessToken:self.accessToken];
    if (createAssetFileStatusCode != 204) {
        NSLog(@"ERROR: Create AssetFile response code: %d", createAssetFileStatusCode);
    }
    //messages = [NSString stringWithFormat:@"%@%n%@", messages, @"File metadata generated."];
    
    //Phase 2: Encoding
    //Obtain th Media Processor
    NSArray *mediaProcessors = [self getMediaProcessors:self.accessToken];
    NSString *mediaEncoderId = [[mediaProcessors objectAtIndex:0] objectForKey: @"Id"];
    NSLog(@"Asset ID: %@", assetId);
    NSLog(@"Media Encoder ID: %@", mediaEncoderId);
    //NSLog(@"Media Processor response: %@",  mediaProcessors);
    //messages = [NSString stringWithFormat:@"%@%n%@", messages, @"MediaProcessor grabbed."];
    
    //TODO: Uncomment and Complete Job request and check if it worked.
    NSDictionary *encodingJobResponse = [self startEncodingJob:@"Encoding from iOS"
                   assetId:assetId
          mediaProcessorId:mediaEncoderId
            encodingPreset:@"H264 Broadband 720p"
               accessToken:self.accessToken];
    NSLog(@"Job response: %@", encodingJobResponse);
    
    //Phase 3: Delivering
    
    //TO BE CONTINUED
    
    //Show the messages on the screen
    self.greetingContent.text = messages;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// URL-encodes a string
- (NSString *)urlEncode:(NSString *) str
{
    NSString *unescaped = str;
    NSString *charactersToEscape = @"!*'();:@&=+$,/?%#[]\" ";
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
    NSString *encodedString = [unescaped stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    return encodedString;
}
@end
