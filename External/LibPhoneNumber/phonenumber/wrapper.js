goog.provide('sphone.phonenumber');

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


sphone.phonenumber = function(phoneNumber, regionCode) {
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    return number.getCountryCode();
};


getCountryCode = function(phoneNumber, regionCode) {
    var phoneUtil = i18n.phonenumbers.PhoneNumberUtil.getInstance();
    var number = phoneUtil.parseAndKeepRawInput(phoneNumber, regionCode);
    return number.getCountryCode();
};


// Ensures the symbol will be visible after compiler renaming.
goog.exportSymbol('sphone.phonenumber', sphone.phonenumber);
goog.exportSymbol('getCountryCode', sphone.phonenumber);
