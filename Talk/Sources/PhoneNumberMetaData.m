//
//  PhoneNumberMetaData.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  Thanks to: https://github.com/bcaccinolo/XML-to-NSDictionary
//
//  This class is only used temporarily to generate a new version of the JSON resource.
//  To make a run, add PhoneNumberMetaData.xml and this module to the target, and reference
//  sharedInstance somewhere.
//  

#import "PhoneNumberMetaData.h"
#import "Common.h"


@interface PhoneNumberMetaData ()
{
    NSMutableArray*     dictionaryStack;
    NSMutableString*    textInProgress;
}

@end


@implementation PhoneNumberMetaData

@synthesize metaData       = _metaData;


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
        NSData*         data = [Common dataForResource:@"PhoneNumberMetaData" ofType:@"xml"];
        NSXMLParser*    parser = [[NSXMLParser alloc] initWithData:data];
        
        dictionaryStack = [[NSMutableArray alloc] init];
        textInProgress = [[NSMutableString alloc] init];
        
        [dictionaryStack addObject:[NSMutableDictionary dictionary]];
        parser.delegate = self;
        if ([parser parse] == YES)
        {
            _metaData = [[[dictionaryStack objectAtIndex:0] objectForKey:@"phoneNumberMetadata"] objectForKey:@"territories"];
        }
        else
        {
            _metaData = nil;
        }
        
        //### Here's where the generated JSON is printed.  Copy-paste it to NumberMetaData.json.
        NSString* json = [Common jsonStringWithObject:_metaData];
        NSLog(@"%@", json);
    }

    return self;
}


#pragma mark - NSXMLParser Delegate

- (void)parser:(NSXMLParser*)parser
didStartElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
    attributes:(NSDictionary*)attributeDictionary
{
    if ([elementName isEqualToString:@"territory"])
    {
        elementName = [attributeDictionary objectForKey:@"id"];
        
        // Remove "id", because it's redundant.
        NSMutableDictionary*    dictionary = [NSMutableDictionary dictionary];
        [dictionary addEntriesFromDictionary:attributeDictionary];
        [dictionary removeObjectForKey:@"id"];
        attributeDictionary = dictionary;
    }
    
    // Get the dictionary for the current level in the stack.
    NSMutableDictionary*    parentDictionary = [dictionaryStack lastObject];

    if ([elementName isEqualToString:@"leadingDigits"])
    {
        NSMutableArray* childArray = [parentDictionary objectForKey:@"leadingDigits"];
        
        if (childArray == nil)
        {
            childArray = [NSMutableArray array];
            [parentDictionary setObject:childArray forKey:@"leadingDigits"];
        }

        [dictionaryStack addObject:childArray];
    }
    else if ([elementName isEqualToString:@"numberFormat"])
    {
        // Create the child dictionary for the new element, and initilaize it with the attributes.
        NSMutableDictionary*    childDictionary = [NSMutableDictionary dictionary];
        [childDictionary addEntriesFromDictionary:attributeDictionary];

        NSMutableArray* array = nil;
        if ([[parentDictionary objectForKey:elementName] isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it.
            array = (NSMutableArray*)[parentDictionary objectForKey:elementName];
        }
        else
        {
            // Create an array if it doesn't exist.
            array = [NSMutableArray array];

            // Replace the child dictionary with an array of child dictionaries.
            [parentDictionary setObject:array forKey:elementName];
        }

        // Add the new child dictionary to the array.
        [array addObject:childDictionary];

        // Update the stack.
        [dictionaryStack addObject:childDictionary];
    }
    else
    {
        // Create the child dictionary for the new element, and initilaize it with the attributes.
        NSMutableDictionary*    childDictionary = [NSMutableDictionary dictionary];
        [childDictionary addEntriesFromDictionary:attributeDictionary];

        // If there's already an item for this key, it means we need to create an array.
        id existingValue = [parentDictionary objectForKey:elementName];
        if (existingValue)
        {
            NSMutableArray* array = nil;
            if ([existingValue isKindOfClass:[NSMutableArray class]])
            {
                // The array exists, so use it.
                array = (NSMutableArray*)existingValue;
            }
            else
            {
                // Create an array if it doesn't exist.
                array = [NSMutableArray array];
                [array addObject:existingValue];

                // Replace the child dictionary with an array of child dictionaries.
                [parentDictionary setObject:array forKey:elementName];
            }

            // Add the new child dictionary to the array.
            [array addObject:childDictionary];
        }
        else
        {
            // No existing value, so update the dictionary.
            [parentDictionary setObject:childDictionary forKey:elementName];
        }
        
        // Update the stack.
        [dictionaryStack addObject:childDictionary];
    }
}


- (void)parser:(NSXMLParser*)parser
 didEndElement:(NSString*)elementName
  namespaceURI:(NSString*)namespaceURI
 qualifiedName:(NSString*)qualifiedName
{
    id                      itemInProgress = [dictionaryStack lastObject];
    NSMutableDictionary*    parentDictionary = [dictionaryStack objectAtIndex:[dictionaryStack count] - 2];
    
    if ([elementName isEqualToString:@"territory"])
    {
        elementName = [itemInProgress objectForKey:@"id"];
    }
    
    // Save the text as object in parent.
    if ([textInProgress length] > 0)
    {
        // Look up the key in parent to which the text belongs.
        for (id key in parentDictionary)
        {
            if ([parentDictionary objectForKey:key] == itemInProgress)
            {
                if ([key isEqualToString:@"exampleNumber"])
                {
                    [parentDictionary removeObjectForKey:key];
                }
                else if ([key isEqualToString:@"leadingDigits"])
                {
                    [itemInProgress addObject:textInProgress];
                }
                else
                {
                    [parentDictionary setObject:textInProgress forKey:key];
                }
                
                break;
            }
        }

        textInProgress = [[NSMutableString alloc] init];
    }
    
    // Pop the current dictionary.
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
