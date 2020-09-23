# API Smoke tests


## Using secrets

The terraform module creates a KMS key, and the lambda will automatically pull out any secrets under the `/smoke-tests` path and expose these as environment variables at runtime.

To store a secret. Create a parameter in parameter store,

 - with path starting `/smoke-tests/` (e.g `/smoke-tests/ose-bookings/password`)
 - type `SecureString`
 - KMS key source set to key ID `alias/smoke-tests`
 - data type `text`

The lambda function can access the value at runtime via an environment variable formed by taking the last part of the parameter path, uppercasing it and prefixing it with `SSM_`. 

E.g. The value stored under `/smoke-tests/ose-bookings/password` becomes acessible as  `SSM_PASSWORD`

**Note:** You should ensure that the last part is unique amongst all parameters in the `/smoke-tests/` path, otherwise only one value will be accessible. 

## Running locally

Note to run tests locally you will need to install the `aws-sdk` (this is present in a lambda environment) on top of the other dependencies.

In the `src` directory:

```
# install depdendencies
npm i
npm i --no-save aws-sdk

# run tests
AWS_PROFILE=<account-alias> AWS_REGION=eu-west-1 node run-local.js
```    