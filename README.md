# indy-post-test

A simple Indy based HTTP server example in two versions (Free Pascal and Delphi) which renders a HTML form with one input field and a submit button. If the submit button is pressed and the form data posted, the server will print information about the received input value.

The Free Pascal version uses the LazUTF8 unit. Therefore the TIdURI.URLDecode function returns a wrong result. Without LazUTF8, the result is correct however newer Free Pascal programs make use of the UTF-8 support (see http://wiki.freepascal.org/Unicode_Support_in_Lazarus#Using_UTF-8_in_non-LCL_programs) 

