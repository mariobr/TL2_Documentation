LicensingProvider integration
in persistence service scan the folder licensingProvider and search for any file with the ending .json.
Check it is a valid json file
in folger _getResult there is a file called licenseprovidermanifest.json
this checked if has the valid schema as of the schema file found in the same folder
use the files for reference they will not be deployed with the binaries
the json structure has has Providername and Providersecrects
the is a static class LicenseProviders that returns providers also
find the providername of the manifest and search for it in the list of providers and return the secrets if found
if the provider is found check signature of the Providersecrects with the public key of the provider
if the signature is valid return the Providersecrects but they are called Vendorcodes
store the ProviVendorcodes  in appstate and have a bool for licenseproviderFound if the number is at least 1 with neither deprecated and in production
add all vendorcodes to appstate with their names and vendorcodes and state

