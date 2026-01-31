# License Models

> Namespaces, Roles

## License Model 
* Id (Guid)
* Name
* Version (decimal e.g. "1.2")
* Namespaces[]
* PropertyBag

    * ***License Model PropertyBag***
    * Category
    * ~~ApplicableStage (Feature, Product)~~
    * Required (bool)
    * Name 
    * ValueType
    * Value
* > Reference Enforcement


## Enforcement
* Id 
* Name
* > Reference LicenseModels
* > Reference for Activation

[## License Model Group](../Licensing/Licensing%20Models.md)
* Id
* Name
* Namespaces[]
* > Reference Products or Features

## License Model Service
### Require Roles ["LicenseAdmin"]
* CRUD Enforcement
    * Modify Namespaces
* CRUD License Model
    * Modify Namespaces
    * Modify Properties (License Model)
* CRUD License Model Groups

