This directory contains raw resource files:
* Countries.txt    - pulled from the internet (I forgot, Wikipedia probably)
* Map.text         - made from one of the JavaScript files of Google's libphonenumber
* MCC.txt          - pulled from Wikipedia
* CountryCodes.txt - pulled from http://www.mcc-mnc.com.  This, together with an edited
                     list of names, is all that's used in the app.

For each of these files there's a Python script that transforms them into JSON format.  The JSON files are used in the Talk app.  The Python scripts have a small issue: The closing item ends with a comma, this is incorrect.  this comma must be removed by hand before copying to Xcode project.

Note that the Python scripts generate one comma too much at the end of lists of items.

IMPORTANT: Corrections/Changes were made once the files were placed in the Xcode project.
           So don't just run the scripts and copy-paste!!!  One of the corrections was
           UK -> GB (UK is no ISO country code).  Others: FG -> GF, ZU -> UZ, TP -> TL.