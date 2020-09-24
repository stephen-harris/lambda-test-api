# API Smoke tests

## Deploying

```
# install dependencies
npm i --prefix modules/api-smoke-test/src/ modules/api-smoke-test/src/

# run terraform
terraform init
AWS_PROFILE=booking-nonprod terraform apply -var-file="nonprod.tfvars" -var spec_path=${PWD}/spec .
```

To report to datadog create a a `SecureString` parameter in the parameter store with name `/smoke-tests/${service}/dd_client_api_key` (see *Using secrets* below). 


## Using secrets

The terraform module creates a KMS key, and the lambda will automatically pull out any secrets under the `/smoke-tests/${service}` path and expose these as environment variables at runtime.

To store a secret. Create a parameter in parameter store with:

 - path starting `/smoke-tests/${service}/` (e.g `/smoke-tests/ose-bookings/password`)
 - type `SecureString`
 - KMS key source set to key ID `alias/smoke-tests`
 - data type `text`

The lambda function can access the value at runtime via an environment variable formed by taking the last part of the parameter path, uppercasing it and prefixing it with `SSM_`. 

E.g. The value stored under `/smoke-tests/ose-bookings/password` becomes acessible at runtime as the envrionment variable `SSM_PASSWORD`

**Note:** You should ensure that the last part is unique amongst all parameters in the `/smoke-tests/${service}/` path, otherwise only one value will be accessible. 

## Running locally

Note to run tests locally you will need to install the `aws-sdk` (this is present in a lambda environment) on top of the other dependencies.

In the `src` directory:

```
# install depdendencies
npm i --prefix modules/api-smoke-test/src/ modules/api-smoke-test/src/
npm i --no-save aws-sdk --prefix modules/api-smoke-test/src/ modules/api-smoke-test/src/ 

# run tests
SERVICE=<service-name> AWS_PROFILE=<account-alias> AWS_REGION=eu-west-1 node modules/api-smoke-test/src/run-local.js
```    