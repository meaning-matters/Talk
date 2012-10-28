//
//  PhoneNumberMetaData.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  Thanks to: https://github.com/bcaccinolo/XML-to-NSDictionary

#import "PhoneNumberMetaData.h"

@interface PhoneNumberMetaData ()
{
    NSMutableArray*     dictionaryStack;
    NSMutableString*    textInProgress;
}

@end


@implementation PhoneNumberMetaData

@synthesize dictionary = _dictionary;


static PhoneNumberMetaData* sharedInstance;

+ (void)initialize
{
    sharedInstance = [[PhoneNumberMetaData alloc] init];
}


+ (PhoneNumberMetaData*)sharedInstance
{
    return sharedInstance;
}


- (id)init
{
    if (self = [super init])
    {
        NSString*       path = [[NSBundle mainBundle] pathForResource:@"TestMetaData" ofType:@"xml"];
        NSData*         data = [NSData dataWithContentsOfFile:path];
        NSXMLParser*    parser = [[NSXMLParser alloc] initWithData:data];
        
        dictionaryStack = [[NSMutableArray alloc] init];
        textInProgress = [[NSMutableString alloc] init];
        
        [dictionaryStack addObject:[NSMutableDictionary dictionary]];
        parser.delegate = self;
        if ([parser parse] == YES)
        {
            _dictionary = [dictionaryStack objectAtIndex:0];
        }
        else
        {
            _dictionary = nil;
        }
    }
    
    return self;
}


#pragma mark - NSXMLParser Delegate

- (void)parser:(NSXMLParser*)parser
didStartElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
    attributes:(NSDictionary*)attributeDict
{
    // Get the dictionary for the current level in the stack
    NSMutableDictionary*    parentDictionary = [dictionaryStack lastObject];
    
    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary*    childDictionary = [NSMutableDictionary dictionary];
    [childDictionary addEntriesFromDictionary:attributeDict];
    
    // If there's already an item for this key, it means we need to create an array
    id existingValue = [parentDictionary objectForKey:elementName];
    if (existingValue)
    {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it
            array = (NSMutableArray *) existingValue;
        }
        else
        {
            // Create an array if it doesn't exist
            array = [NSMutableArray array];
            [array addObject:existingValue];
            
            // Replace the child dictionary with an array of children dictionaries
            [parentDictionary setObject:array forKey:elementName];
        }
        
        // Add the new child dictionary to the array
        [array addObject:childDictionary];
    }
    else
    {
        // No existing value, so update the dictionary
        [parentDictionary setObject:childDictionary forKey:elementName];
    }
    
    // Update the stack
    [dictionaryStack addObject:childDictionary];
}


- (void)parser:(NSXMLParser*)parser
 didEndElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qName
{
    // Update the parent dict with text info
    NSMutableDictionary*    dictionaryInProgress = [dictionaryStack lastObject];
    NSMutableDictionary*    parentDictionary = [dictionaryStack objectAtIndex:[dictionaryStack count] - 2];
    
    // Set the text property
    if ([textInProgress length] > 0)
    {
        for (NSString* key in [parentDictionary allKeys])
        {
            if ([parentDictionary objectForKey:key] == dictionaryInProgress)
            {
                [parentDictionary setObject:textInProgress forKey:key];
                break;
            }
        }

        // Reset the text
        textInProgress = [[NSMutableString alloc] init];
    }
    
    // Pop the current dict
    [dictionaryStack removeLastObject];
}


- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string
{
    // Trim newlines followed by spaces.
    NSRegularExpression*    regex = [NSRegularExpression regularExpressionWithPattern:@"\\n[ ]*" options:0 error:nil];
    string = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    
    [textInProgress appendString:string];
}


- (void)parser:(NSXMLParser*)parser parseErrorOccurred:(NSError*)parseError
{
    // Handle errors as appropriate for your application.
}

@end
