# Bypass Stored Value
[![Code Climate](https://codeclimate.com/github/bypasslane/bypass-stored-value.png)](https://codeclimate.com/github/bypasslane/bypass-stored-value)

![Circle CI](https://circleci.com/gh/bypasslane/bypass-stored-value.png?circle-token=866deaf2a9e948cb5d8305eb9e8a88c1ebdc6f92)

Gem to keep all stored value client interactions, and separate it from the main repo

## Usage

### Clients

Supported clients currently include Stadis. Future releases will include SVS and Givex clients. They can be found under the Clients namespace.

#### Stadis

Stadis requires these configuration parameters:

  * Protocol - string
  * Host - string
  * Port - string
  * Vendor Cashier - string
  * Register ID - integer
  * Location ID - integer
  * Username - string
  * Password - string

These are the minimum requirements to establish a connection with Stadis. A Stadis client is initialized by passing username, password and an options hash.   

###### Example Stadis Client Initialization:

```
gateway = BypassStoredValue::Clients::StadisClient.new("username", "password", {protocol: "http", host: "localhost", port: "3000", vendor_cashier: 1, register_id: 1})
```

##### Methods

This lib implements 5 methods to build requests to Stadis:

  * balance
  * account_charge
  * post_transaction
  * refund
  * reload_card

###### BypassStoredValue::Clients::StadisClient#balance(code)

Used to check balance of given code. Accepts a single string argument, the code.

```
gateway.balance("123456")
=> {status_code: 0, authentication_token: nil, charged_amount: nil, remaining_balance: 10.00}
```

###### BypassStoredValue::Clients::StadisClient#account_charge(code, amount)

Used to authorize initial charge. Accepts a string, the code, and a float, the amount.  Stadis requires a two-step authorization/capture process.  We use account_charge to perform the authorization portion and post_transaction to perform the capture portion. This is to replicate the auth/capture flow for credit cards.

```
gateway.account_charge("123456", 2.50)
=> {status_code: 0, authentication_token: "11111", charged_amount: 2.50, remaining_balance: 7.50}
```

###### BypassStoredValue::Clients::StadisClient#post_transaction(line_items, payments)

Used to capture transaction.  Accepts an array of line item hashes and an array of payment hashes.  Stadis requires all line items and all payments for the order, to reconcile their records and report usage accurately. Note the structure of the line items and payments hashes, it is required.

```
array_of_line_items = [{item_id: 1, item_name: "foo", count: 1, unit_price: 2.00}, {item_id: 2, item_name: "bar", count: 1, unit_price: 3.00}]
=> [{item_id: 1, item_name: "foo", count: 1, unit_price: 2.00}, {item_id: 2, item_name: "bar", count: 1, unit_price: 3.00}]

array_of_payments = [{stadis: true, transaction_id: "11111", cash: false, amount: 2.00}, {stadis: false, transaction_id: nil, cash: false, amount: 3.00}]
=> [{stadis: true, transaction_id: "11111", cash: false, amount: 2.00}, {stadis: false, transaction_id: nil, cash: false, amount: 3.00}]

gateway.post_transaction(array_of_line_items, array_of_payments)
=> {status_code: 0}
```

###### BypassStoredValue::Clients::StadisClient#refund(code, authorization_id, amount)

Used to fully refund original amount.  Accepts a string, the code, a string, the authorization id of the original transaction, and a float, the amount. Stadis does not support partial refunds.

```
gateway.refund("123456", "11111", 2.50)
=> {status_code: 0, authentication_token: "11111", charged_amount: 2.50, remaining_balance: 10.00}
```

###### BypassStoredValue::Clients::StadisClient#reload_card(code, amount)

Used to reload a card, mostly for testing purposes. Accepts a string, the code, and a float, the amount. Bypass doesn't offer a customer-facing interface for adding amounts to stored value cards, so we use this to reload a test card after using its value.

```
gateway.reload_card("123456", 10.00)
=> {status_code: 0, authentication_token: nil, charged_amount: nil, remaining_amount: 10.00}
```

### Response

The response received from BypassStoredValue will always be a hash with a status_code key.  Depending on the request, the response may contain other pertinent information, such as the charged amount or the amount remaining on the card.  Status codes return 0+ for successful requests, and <0 for failed requests.  A sample response will look like:

```
=> {status_code: 0, authentication_token: "11111", charged_amount: 2.50, remaining_balance: 7.50}
```

Response#successful? parses the resulting response hash and returns true for responses with status code >=0 and false for status codes <0. Since each action in StadisClient returns a Response object, this response can be stored and checked easily for success using the #successful? method.

```
response = gateway.account_charge("123456", 2.50)
=> {status_code: 0, authentication_token: "11111", charged_amount: 2.50, remaining_balance: 7.50}

response.successful?
=> true

response = gateway.account_charge("123456", 2.50)
=> {status_code: -1, authentication_token: "11111", charged_amount: 0.00, remaining_balance: 0.00}

response.successful?
=> false
```

