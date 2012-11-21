// For reasons I don't understand (yet), closurebuilder.py is required
// to have a --namespace option.  I've added 'dummy' as namespace, to
// just make it work.
goog.provide('dummy');

goog.require('goog.dom');
goog.require('goog.json');
goog.require('goog.proto2.ObjectSerializer');
goog.require('goog.array');
goog.require('goog.proto2.PbLiteSerializer');
goog.require('goog.string');
goog.require('goog.proto2.Message');
goog.require('goog.string.StringBuffer');

goog.require('i18n.phonenumbers.NumberFormat');
goog.require('i18n.phonenumbers.PhoneNumber');
goog.require('i18n.phonenumbers.PhoneNumberUtil');
goog.require('i18n.phonenumbers.AsYouTypeFormatter');


getCountryCode = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    
    return number.getCountryCode();
};


getRegionCodeForNumber = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);

    return phoneUtil.getRegionCodeForNumber(number);
};


isValidNumber = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    
    return phoneUtil.isValidNumber(number);
};


isValidNumberForRegion = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    
    return phoneUtil.isValidNumberForRegion(number, regionCode);
};


isPossibleNumber = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    
    return phoneUtil.isPossibleNumber(number);
};


getNumberType = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    var type;
    var PNT = i18n.phonenumbers.PhoneNumberType;
    switch (phoneUtil.getNumberType(number)) {
        case PNT.FIXED_LINE:
            type = 'fixed-line';
            break;
        case PNT.MOBILE:
            type = 'mobile';
            break;
        case PNT.FIXED_LINE_OR_MOBILE:
            type = 'fixed-line or mobile';
            break;
        case PNT.TOLL_FREE:
            type = 'toll-free';
            break;
        case PNT.PREMIUM_RATE:
            type = 'premium-rate';
            break;
        case PNT.SHARED_COST:
            type = 'shared-cost';
            break;
        case PNT.VOIP:
            type = 'VoIP';
            break;
        case PNT.PERSONAL_NUMBER:
            type = 'personal number';
            break;
        case PNT.PAGER:
            type = 'pager';
            break;
        case PNT.UAN:
            type = 'UAN';
            break;
        case PNT.UNKNOWN:
            type = 'unknown';
            break;
    }
    
    return type;
};


getOriginalFormat = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    
    return phoneUtil.formatInOriginalFormat(number, regionCode);
};


getE164Format = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    var PNF = i18n.phonenumbers.PhoneNumberFormat;
    
    return phoneUtil.isValidNumber(number)
               ? phoneUtil.format(number, PNF.E164)
               : 'invalid';
};


getInternationalFormat = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    var PNF = i18n.phonenumbers.PhoneNumberFormat;
    
    return phoneUtil.isValidNumber(number)
               ? phoneUtil.format(number, PNF.INTERNATIONAL)
               : 'invalid';
};


getNationalFormat = function(phoneNumber, regionCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    var PNF = i18n.phonenumbers.PhoneNumberFormat;
    
    return phoneUtil.isValidNumber(number)
               ? phoneUtil.format(number, PNF.NATIONAL)
               : 'invalid';
};


getOutOfCountryCallingFormat = function(phoneNumber, regionCode, countryCode)
{
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    var PNF = i18n.phonenumbers.PhoneNumberFormat;
    return phoneUtil.isValidNumber(number)
               ? phoneUtil.formatOutOfCountryCallingNumber(number, countryCode)
               : 'invalid';
};


getAsYouTypeFormat = function(phoneNumber, regionCode)
{
    var formatter = new i18n.phonenumbers.AsYouTypeFormatter(regionCode);
    var phoneNumberLength = phoneNumber.length;
    var i;
    for (i = 0; i < phoneNumberLength - 1; ++i)
    {
        var inputChar = phoneNumber.charAt(i);
        formatter.inputDigit(inputChar);
    }
    
    return formatter.inputDigit(phoneNumber.charAt(i));
};


// Ensures the symbols will be visible after compiler renaming.  The
// dummy.dummy here has nothing to do with namespaces.  Same here: I
// have no idea why it's needed; just added something to make it work.
goog.exportSymbol('getCountryCode',               dummy.dummy);
goog.exportSymbol('isValidNumber',                dummy.dummy);
goog.exportSymbol('isValidNumberForRegion',       dummy.dummy);
goog.exportSymbol('getRegionCodeForNumber',       dummy.dummy);
goog.exportSymbol('getNumberType',                dummy.dummy);
goog.exportSymbol('getOriginalFormat',            dummy.dummy);
goog.exportSymbol('getE164Format',                dummy.dummy);
goog.exportSymbol('getInternationalFormat',       dummy.dummy);
goog.exportSymbol('getNationalFormat',            dummy.dummy);
goog.exportSymbol('getOutOfCountryCallingFormat', dummy.dummy);
goog.exportSymbol('getAsYouTypeFormat',           dummy.dummy);






