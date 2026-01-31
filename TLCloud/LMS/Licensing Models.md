# License Models
## Memory
* Feature and Product Models may contain Memory for custom scenarios. 
* The associated memory should be restricted at license generation time but is technically unlimited.
* A license generator could also restrict it to a certain type like JSON.
* Memory may contain a header section defining what is transported.
  > e.g. JSON, XML, BINARY

# License Model Group
* A license model group represents a license model for a product or a set of features.
* An option could be to define a license model group for a product and associate the license model to it. Means all features of the product use the license model of the group.
* Another option could be to define a token for a set of features inheriting the license model of the license model group.
* Features can have individual license models.


# Feature License Models

## Common Properties
* All features are bound via TPM or Fingerprint.
* All features have a seat count
* Seat count 0 is a standalone license and cannot be accessed via network

## Conventional
### Perpetual
* Feature valid forever
## Persistence Required
### Time Period 
* Feature valid from(optional) to a time
* Time definition is UTC - needs to be transformed to client local time
* Implies time validation configured via a tolerance in minutes
	* via TPM or Persistence
### Trial (first Use)
* Feature valid when it is first consumed for an amount of days
* After first usage same behavior as Time Period
### Trial (consumption based)
* Offer an amount of time
* Decrements time during license consumption (Login, Logoff)
### Counter based - *Decrement*
* Each time feature is consumed the counter is decremented by the number passed
* Invalidates when decremented to 0
### Counter based - *Increment*
* Each time a feature is consumed the counter is incremented with or without a possible limit
* A reset process can be used to make sure the counter does get reset to zero but reporting to License Management System is guaranteed.
### Token based
* Features are consumed using Tokens.
* A function can consume an amount of tokens at once
* A client can have an amount of tokens.
* Tokens are stored in persistence.
* Tokens can be exportable between clients and license managers.
* Exportable and revocable tokens can be returned to License Management system
> Trading tokens?
> Who can trade? What is the model to allow trading?
## Dependent on Activation
### Time Period (with Activation)
* Features time period get set at Activation time.
* After activation same behavior as Time Period
### Unique List based - *License Manager Only*
* A list of unique Ids passed at consumption time
* Max number of valid list items
* Max number of list items (up to infinity)
> Ability to remove items from the valid list (Admin?)
# Product License Models
## Common Properties
* Products are part of the clients data.
### Exportable
* A product marked as exportable can be moved between clients or license managers.
> Export? Restrictions beyond Vendor Code?
* The export is using a file packaging format allowing to export 
	* peer to peer between clients or license managers
	* via a license manager route
	* via License Management system route
### Revoke
* A product marked as exportable can also be revoked (permanently disappear).
* The revocation is a client/license manager process requiring blacklisting the product being revoked
	* A revoked product cannot be restored from backup
