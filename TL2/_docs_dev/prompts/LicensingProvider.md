LicensingProvider integration
in persistence service scan the folder licensingProvider and search for any file with the ending .json.
Check it is a valid json file
this is the json structure
{
  "ProviderName": "MBFEB0426",
  "CreatedUtc": "2026-02-04T17:55:22.2175403+00:00",
  "ProviderSecrets": [
    {
      "VendorCode": "0b290513-6dd2-4be3-9a08-8402543a4941",
      "VendorSecretName": "MBB",
      "RsaKeySize": 2048,
      "PublicKey": "LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUFxZVB0YWIxTXU1QmVKSllRNmREMwpkTzRkSGJQOFcwSHdHMkdsS2w4S09PNXVqbGR3bGlTTzJZdFh3MG1QdU5LcG1sbWRmZnliZldDSXhXWjBUQU95CnVkSGREMXAwRlJXTnFLU2ZHQVlVSFF3T3pBbHEyWXBiak5STytKaGJOdHkyWmRHc1NpS25oNUo5RythRU05bWoKdDlYNmpLakdsSGtlWVBwbzl3VXErUEE2c1VTNFBEV0k4UDB0ZldNZlpSWE5BY1JCaVdjNVFNbDdCZmNvcEhNeQpub21ZOVFFOUY5K2paRTIzMTZKaVNBUXJhY0s5WjI2blM4ZlhKVWJMcXlYUDVVeC9ySFVOUU03dVp5QmhFOFZ6CnA2ckl0VVRpeW9YMjIxRjhwUGxBTm5XZFdJeWUwU3dDYlR6N1J4c2JMeXc4U0cxaUlHSndjKzk2YjcyZTlKOU0KS1FJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0t",
      "InProduction": true,
      "Deprecated": false
    },
    {
      "VendorCode": "825b2c67-293a-4489-9aff-dbca93b5d872",
      "VendorSecretName": "VENDOR_ROOT",
      "RsaKeySize": 2048,
      "PublicKey": "LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF0R21jMDlSc3pFNEUzVEpyK3MyUgpmSGdKWElmVGJ1Mm5TdmdqcXFqNDFiSFpQS1R6RUpMMzR5VU1ZK1VqQllmbDV4SXRWMGN3NnpEbGZQcmEzNHJQCnJOcVNXekwrL0FKdFFnZE9Rcnp5a29XRVA0Szl0ZXI1NXZUV2lCTWVQbUxSa0NaQWdYV0k5c1FLUmc3WVFVZEEKSEprMzZvd3dhZmxuZHM0dlFGYTQ3OEpvNGs2dngwdTQ4MHRTM3ZUa3pTclVCWGFHcDVxNEVxbUpHNCtUQ3RrdQp3WmlTTFBtSFRubmF4dUhvenZGRVVuS1dFMS9CRXNmdTk2bHVObVRhTjAxT0Uza05EaVp1NjNIamJ3YVB5N3loClVkWFNFUkJWalRPUGV6b3dEQkVHMnNXODU5N0xoaCtBelB4MXhaanhmb0ptMlhoc2h0bUZyMTZBSWFOZmhTMy8KTVFJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0t",
      "InProduction": false,
      "Deprecated": false
    }
  ],
  "SignatureBase64": "dbXUlQA1Z7yIkRqRj4Z/Clmzci5q6VPGHYCTK128b9QX3NwpR6fVnjBv/x3v\u002Bur8Rj5nLd3sor/j3B63ar9SDu3R8J3u8/RlP6Ika2Gb8KTGNRMCs1hFZKM9Vjm110oeXZJaYVeqbRVBYgKrkJlSljTKlKUhOBNgB8jjD8XoljGkXqt6qyVRBEBH1J8sK7SRHYhh2UVrRl0asNQETNQxF5H/NLmTi5WLTwo0cjoynZK02qLJsd5mR/2eIpYIZOziPIkcCztHOfBrYPWtezIsd7\u002BAK7\u002BONYqttvseMT3N/2V3ilW40hTS1onaUHmUuz2F3/dF/XIWu6b4d/fjHwykkg=="
}

this is the schema

{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "LicenseProviderManifest",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "ProviderName",
    "CreatedUtc",
    "ProviderSecrets",
    "SignatureBase64"
  ],
  "properties": {
    "ProviderName": {
      "type": "string",
      "minLength": 1
    },
    "CreatedUtc": {
      "type": "string",
      "format": "date-time"
    },
    "ProviderSecrets": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": [
          "VendorCode",
          "VendorSecretName",
          "RsaKeySize",
          "PublicKey"
        ],
        "properties": {
          "VendorCode": {
            "type": "string",
            "format": "uuid"
          },
          "VendorSecretName": {
            "type": "string",
            "minLength": 1
          },
          "RsaKeySize": {
            "type": "integer",
            "minimum": 512
          },
          "PublicKey": {
            "type": "string",
            "minLength": 1,
            "description": "Base64-encoded PEM public key"
          }
        }
      }
    },
    "SignatureBase64": {
      "type": "string",
      "minLength": 1,
      "description": "Base64 signature"
    }
  }
}

validate the json schema


the json structure has  Providername and Providersecrects
there is a static class LicenseProviders that returns providers 
find the providername of the manifest and search for it in the list of providers and return the Providersecrets if found
if the provider is found check signature of the Providersecrects array with the public key of the provider
if the signature is valid return the Providersecrects but they are called Vendorcodes
store the Vendorcodes  in appstate and have a bool for licenseproviderFound if the number is at least 1 with neither deprecated and in production
add all vendorcodes to appstate with their names and vendorcodes and state

