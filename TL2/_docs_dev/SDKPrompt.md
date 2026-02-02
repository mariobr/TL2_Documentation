I want to create an SDK called SDK-TrustedLicensing
it will contain documentation and sample code and libraries
TLLicensemanager will be part of it but I want to ship it in a way that the user who is using the SDK can compile it with the option of CustomLocking
and must provide the RSA License Provider public key in an include file
the provider key is generated elsewhere
the sdk should include everything needed to use cmake to create the samples and tllicensemanager
the samples should be sperated in Java, DotNet, C++
the libraries will be devided in Windows, Linux and CPU architecture