# New Orders API Testing

## Overview

This testing repo (written in RSpec) is designed to validate the "New Order" endpoint of the Gemini Exchange API. We are treating this as a brand new endpoint and running it through the gauntlet of functional testing to validate the endpoint's Methods, Validations, and Authentication access.

Our goal is to ensure that all positive use cases are validated so the endpoint is working as Product has intended it to work. We also want to assert all negative test cases we can possibly convceive of have been thoroughly tested to avoid any unwanted or unintended behavior in production, either by user error or users with malicious intent.

## Assumptions

- This is brand new endpoint that has never been exposed before
- Git branch where new endpoint changes are located has passed Regression tests
- Branch will be load-tested separately
- Security will be testing the branch separately after functional testing
- UI testing will happen in conjunction with UI feature changes on separate branch

## Testing Plan

- Methods
  The __how__ of the endpoint. These test cases assert how a user can interact with the endpoint. It specifically tests what methods are allowed on this endpoint and which are not. We are going through our REST protocol (GET, POST, PUT, DELETE) in order to validate.

  In POST request context (only method allowed on endpoint), we are digging in a bit deeper with our test cases to validate that user is only allowed to POST to endpoint with a _valid payload_ (in header, base64-encoded and signed via SHA384). Requests with payload in body or not correctly encoded should return errors.

- Model Validations
  This section is the __what__ and __why__ of the endpoint. We test that all the required fields in the payload are actually required by leaving each one out individually from our standard payload.

  We also test that we are receiving all expected fields (and correct field value types) in response from endpoint. With certain fields that have specific validations, we also assert that they are validating inputs correctly:
    - **nonce** should be an incrementing unique number for each request
    - **client_order_id** is a string with certain permitted characters with length between 1-100
    - **symbol** field should accept only valid symbols and reject all others
    - **amount** field should validate and enforce minimum order amounts on a per-symbol basis
    - **options** field should be optional (w/ default), and accept only one valid order execution option per new order request

- Authentication
  The __who__ of this endpoint. Here we test access based on roles, asserting who has the ability to send requests to this endpoint and who doesn't. We want to make sure we get the right error code response, where user is **FORBIDDEN** from using endpoint upon authentication.

## Getting Started

These instructions will get the included tests up and running on your local machine.

### Prerequisites

```
ruby 2.3.1
bundler 1.12.5
```

### Installing
From the command terminal, clone the repository to your local directory...
```
$ git clone https://www.github.com/izzydoesit/gemini_api.git
$ cd gemini_api
```

Then run bundle command to install all dependencies.

```
$ bundle install
```

## Running ALL the tests

```
bundle exec rspec spec
```
or simply
```
rspec
```

### Dependencies

* [RSpec](http://rspec.info) - Ruby Testing Framework
* [OpenSSL](https://www.openssl.org/) - Toolkit for Transport Layer Security (TLS) & Secure Sockets Layer (SSL) protocols
* [Faraday](https://faraday.com) - HTTP REST client
* [Byebug](https://github.com/deivid-rodriguez/byebug) - Debugging tool for Ruby
* [Awesome Print](https://www.github.com/awesome-print/awesome_print) - Formatted printing of Ruby objects with style
* [DotENV](https://github.com/bkeepers/dotenv) - Shim to load environment variables in development

# Author
* **Israel Matos** ([Portfolio](https://www.israeldmatos.com) | [LinkedIn](https://linkedin.com/in/israeldmatos) | [Github](https://github.com/izzydoesit))

# License

This project is licensed under the Apache 2.0 License - see [LICENSE.md](LICENSE.md) file for details
