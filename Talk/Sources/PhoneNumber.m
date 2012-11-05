//
//  PhoneNumber.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  Description of NumberMetaData.json format:
//
//  The ISO 3166-1 alpha-2 representation of a country/region, with the
//  exception of "country calling codes" used for non-geographical entities,
//  such as Universal International Toll Free Number (+800). These are all
//  given the ID "001", since this is the numeric region code for the world
//  according to UN M.49: http://en.wikipedia.org/wiki/UN_M.49
//
//  availableFormats (optional, repeated):
//      pattern (single, required):
//          Regex that is used to match the national (significant) number. For
//          example, the pattern "(20)(\d{4})(\d{4})" will match number
//          "2070313000", which is the national (significant) number for Google
//          London.
//          Note the presence of the parentheses, which are capturing groups
//          what    specifies the grouping of numbers.
//
//      format (single, required):
//          Specifies how the national (significant) number matched by pattern
//          should be formatted.  Using the same example as above, format could
//          contain "$1 $2 $3", meaning that the number should be formatted as
//          "20 7031 3000".  Each $x are replaced by the numbers captured by
//          group x in the regex specified by pattern.
//
//      intlFormat (optional):
//          This field is populated only when the national significant number is
//          formatted differently when it forms part of the INTERNATIONAL format
//          and NATIONAL format. A case in point is mobile numbers in Argentina:
//          The number, which would be written in INTERNATIONAL format as
//          +54 9 343 555 1212, will be written as 0343 15 555 1212 for NATIONAL
//          format. In this case, the prefix 9 is inserted when dialling from
//          overseas, but otherwise the prefix 0 and the carrier selection code
//          15 (inserted after the area code of 343) is used.
//          Note: this field is populated by setting a value for <intlFormat>
//          inside the <numberFormat> tag in the XML file. If <intlFormat> is
//          not set then it defaults to the same value as the <format> tag.
//
//          Examples:
//              To set the <intlFormat> to a different value than the <format>:
//                  <numberFormat pattern=....>
//                      <format>$1 $2 $3</format>
//                      <intlFormat>$1-$2-$3</intlFormat>
//                  </numberFormat>
//
//              To have a format only used for national formatting, set
//              <intlFormat> to "NA":
//                  <numberFormat pattern=....>
//                      <format>$1 $2 $3</format>
//                      <intlFormat>NA</intlFormat>
//                  </numberFormat>
//
//          IMPORTANT: In the JSON format, the numberFormat tag has been
//                     eliminated, because it is redundant; availableFormats
//                     is an array containing a number of these.
//
//      leadingDigits (multiple, required):
//          This field is a regex that is used to match a certain number of
//          digits  at the beginning of the national (significant) number. When
//          the match is successful, the accompanying pattern and format should
//          be used to format this number. For example, if leadingDigits=
//          "[1-3]|44", then all the national numbers starting with 1, 2, 3 or
//          44 should be formatted using the accompanying pattern and format.
//
//          The first leadingDigitsPattern matches up to the first three digits
//          of the national (significant) number; the next one matches the first
//          four digits, then the first five and so on, until the leadingDigits
//          pattern can uniquely identify one pattern and format to be used to
//          format the number.
//
//          In the case when only one formatting pattern exists, no leadingDigits
//          is needed.
//
//      nationalPrefixFormattingRule (single, optional):
//          This field specifies how the national prefix ($NP) together with the
//          first group ($FG) in the national significant number should be
//          formatted in the NATIONAL format when a national prefix exists for a
//          certain country.  For example, when this field contains "($NP$FG)",
//          a number from Beijing, China (whose $NP = 0), which would by default
//          be formatted without national prefix as 10 1234 5678 in NATIONAL
//          format, will instead be formatted as (010) 1234 5678; to format it
//          as (0)10 1234 5678, the field would contain "($NP)$FG". Note $FG
//          should always be present in this field, but $NP can be omitted. For
//          example, having "$FG" could indicate the number should be formatted
//          in NATIONAL format without the national prefix.  This is commonly
//          used to override the rule specified for the territory in the XML
//          file.
//
//          When this field is missing, a number will be formatted without
//          national prefix in NATIONAL format. This field does not affect how a
//          number is formatted in other formats, such as INTERNATIONAL.
//
//          IMPORTANT: Also appears at bottom level, also with vailableFormats.
//
//      nationalPrefixOptionalWhenFormatting (single, optional):
//          This boolean field specifies whether the $NP can be omitted when
//          formatting a number in national format, even though it usually
//          wouldn't be.  For example, a UK number would be formatted by our
//          library as 020 XXXX XXXX.  If we have commonly seen this number
//          written by people without the leading 0, for example as
//          (20) XXXX XXXX, this field would be set to true. This will be
//          inherited from the value set for the territory in the XML file,
//          unless a nationalPrefixFormattingRule is defined specifically for
//          this numberFormat (one of the availableFormats).
//
//          IMPORTANT: Also appears at bottom level, also with vailableFormats.
//
//      carrierCodeFormattingRule (single, optional):
//          This field specifies how any carrier code ($CC) together with the
//          first group ($FG) in the national significant number should be
//          formatted when formatWithCarrierCode is called, if carrier codes are
//          used for a certain country.
//
//          IMPORTANT: Also appears at bottom level, also with vailableFormats.
//
//  generalDesc/fixedLine/mobile/tollFree/premiumRate/sharedCost/
//  personalNumber/voip/pager/uan/emergency/voicemail/noInternationalDialling
//      nationalNumberPattern (single, optional):
//          The nationalNumberPattern is the pattern that a valid national
//          significant number would match. This specifies information such as
//          its total length and leading digits.
//
//      possibleNumberPattern (single, optional):
//          The possibleNumberPattern represents what a potentially valid phone
//          number for this region may be written as.  This is a superset of the
//          nationalNumberPattern above and includes numbers that have the area
//          code omitted.  Typically the only restrictions here are in the
//          number of digits.  This could be used to highlight tokens in a text
//          that may be a phone number, or to quickly prune numbers that could
//          not possibly be a phone number for this locale.
//
//      The generalDesc contains information which is a superset of descriptions
//      for all types of phone numbers.  If any element is missing in the
//      description of a specific type in the XML file, the element will inherit
//      from its counterpart in the generalDesc.  Every locale is assumed to
//      have fixed line and mobile numbers - if these types are missing in the
//      XML file, they will inherit all fields from the generalDesc. For all
//      other types, if the whole type is missing in the XML file, it will be
//      given a nationalNumberPattern of "NA" and a possibleNumberPattern of "NA".
//
//      The noInternationalDialling rules distinguish the numbers that are only
//      able to be dialled nationally.
//
//      ### areaCodeOptional is there too.  No idea what it's for.
//
//  countryCode (required):
//      The country calling code that one would dial from overseas when trying
//      to dial a phone number in this country. For example, this would be "64"
//      for New Zealand.
//
//  internationalPrefix (required):
//      The internationalPrefix of country A is the number that needs to be
//      dialled from country A to another country (country B). This is followed
//      by the country code for country B. Note that some countries may have more
//      than one international prefix, and for those cases, a regular expression
//      matching the international prefixes will be stored in this field.
//
//  preferredInternationalPrefix (optional):
//      If more than one international prefix is present, a preferred prefix can
//      be specified here for out-of-country formatting purposes. If this field
//      is not present, and multiple international prefixes are present, then
//      "+" will be used instead.
//
//  nationalPrefix (optional):
//      The national prefix of country A is the number that needs to be dialled
//      before the national significant number when dialling internally. This
//      would not be dialled when dialling internationally. For example, in New
//      Zealand, the number that would be locally dialled as 09 345 3456 would be
//      dialled from overseas as +64 9 345 3456. In this case, 0 is the national
//      prefix.
//
//  preferredExtnPrefix (optional):
//      The preferred prefix when specifying an extension in this country. This
//      is used for formatting only, and if this is not specified, a suitable
//      default should be used instead. For example, if you wanted extensions to
//      be formatted in the following way: 1 (365) 345 445 ext. 2345 " ext. "
//      should be the preferred extension prefix.
//
//  nationalPrefixForParsing (optional):
//      This field is used for cases where the national prefix of a country
//      contains a carrier selection code, and is written in the form of a
//      regular expression. For example, to dial the number 2222-2222 in
//      Fortaleza, Brazil (area code 85) using the long distance carrier Oi
//      (selection code 31), one would dial 0 31 85 2222 2222. Assuming the
//      only other possible carrier selection code is 32, the field will
//      contain "03[12]".
//
//      When it is missing from the XML file, this field inherits the value of
//      nationalPrefix, if that is present.
//
//  nationalPrefixTransformRule (optional):
//      This field is only populated and used under very rare situations.  For
//      example, mobile numbers in Argentina are written in two completely
//      different ways when dialed in-country and out-of-country
//      (e.g. 0343 15 555 1212 is exactly the same number as +54 9 343 555 1212).
//      This field is used together with nationalPrefixForParsing to transform
//      the number into a particular representation for storing in the
//      phonenumber proto buffer in those rare cases.
//
//  sameMobileAndFixedLinePattern (optional, default=false): DOES NOT OCCUR HERE!!!
//      Specifies whether the mobile and fixed-line patterns are the same or not.
//      This is used to speed up determining phone number type in countries where
//      these two types of phone numbers can never be distinguished.
//
//  availableFormats:
//      Note that the number format here is used for formatting only, not
//      parsing.  Hence all the varied ways a user *may* write a number need not
//      be recorded - just the ideal way we would like to format it for them.
//      When this element is absent, the national significant number will be
//      formatted as a whole without any formatting applied.
//
//  mainCountryForCode (optional, default=false):
//      This field is set when this country is considered to be the main country
//      for a calling code. It may not be set by more than one country with the
//      same calling code, and it should not be set by countries with a unique
//      calling code. This can be used to indicate that "GB" is the main country
//      for the calling code "44" for example, rather than Jersey or the Isle of
//      Man.
//
//  leadingDigits (optional):
//      This field is populated only for countries or regions that share a country
//      calling code. If a number matches this pattern, it could belong to this
//      region. This is not intended as a replacement for IsValidForRegion, and
//      does not mean the number must come from this region (for example, 800
//      numbers are valid for all NANPA countries.) This field should be a regular
//      expression of the expected prefix match.
//
//  leadingZeroPossible (optional, default=false):
//      The leading zero in a phone number is meaningful in some countries (e.g.
//      Italy). This means they cannot be dropped from the national number when
//      converting into international format. If leading zeros are possible for
//      valid international numbers for this region/country then set this to true.
//      This only needs to be set for the region that is the main_country_for_code
//      and all regions associated with that calling code will use the same
//      setting.

#import "PhoneNumber.h"
#import "Common.h"


@interface PhoneNumber ()
{
}

@end


@implementation PhoneNumber

@synthesize baseIsoCountryCode   = _baseIsoCountryCode;
@synthesize numberIsoCountryCode = _numberIsoCountryCode;

static NSDictionary*    numberMetaData;
static NSDictionary*    countryCodesMap;
static NSString*        defaultBaseIsoCountryCode;


+ (void)initialize
{
    numberMetaData  = [Common objectWithJsonData:[Common dataForResource:@"NumberMetaData"  ofType:@"json"]];
    countryCodesMap = [Common objectWithJsonData:[Common dataForResource:@"CountryCodesMap" ofType:@"json"]];
}


+ (void)setDefaultBaseIsoCountryCode:(NSString*)isoCountryCode
{
    defaultBaseIsoCountryCode = isoCountryCode;
}


+ (NSString*)defaultBaseIsoCountryCode
{
    return defaultBaseIsoCountryCode;
}


- (id)init
{
    if (self = [super init])
    {
        _baseIsoCountryCode = defaultBaseIsoCountryCode;
    }
    
    return self;
}


- (id)initWithNumber:(NSString*)number
{
    if (self = [super init])
    {
        _baseIsoCountryCode = defaultBaseIsoCountryCode;
    }
    
    return self;
}


- (id)initWithNumber:(NSString*)number baseIsoCountryCode:(NSString*)isoCountryCode;
{
    if (self = [super init])
    {
        _baseIsoCountryCode = isoCountryCode;
    }
    
    return self;
}


- (BOOL)isValid
{
    BOOL    valid = NO;
    
    return valid;
}


- (BOOL)isValidForBaseIsoCountryCode
{
    return [self.numberIsoCountryCode isEqualToString:self.baseIsoCountryCode];
}


- (BOOL)isPossible
{
    BOOL    possible = NO;
    
    return possible;
}


- (PhoneNumberType)type
{
    return PhoneNumberTypeUnknown;
}


- (NSString*)e164Format
{
    
}


- (NSString*)originalFormat
{
    
}


- (NSString*)internationalFormat
{
    
}


- (NSString*)nationalFormat
{
    
}


- (NSString*)outOfCountryFormatFromIsoCountryCode:(NSString*)isoCountryCode
{
    
}


- (NSString*)asYouTypeFormat:(NSString*)partialNumber
{
    
}

@end
