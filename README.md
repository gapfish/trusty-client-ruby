# Trustly-client-ruby

This is an example implementation of communication with the Trustly API using Ruby. This a ruby gem that allows you use Trustly Api calls in ruby.

It implements the standard Payments API as well as gives stubs for executing calls against the API used by the backoffice.

For full documentation on the Trustly API internals visit our developer website: http://trustly.com/developer . All information about software flows and call patters can be found on that site. The documentation within this code will only cover the code itself, not how you use the Trustly API.

This code is provided as-is, use it as inspiration, reference or drop it directly into your own project and use it.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'trustly-client-ruby', require: 'trustly'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install trustly-client-ruby

If you use rails, you can use this generator in order to let trustly find your certificates:

    $ rails g trustly:install

This will copy trustly public certificates under certs/trustly folder:
    
    certs/trustly/test.trustly.public.pem
    certs/trustly/live.trustly.public.pem

You will need to copy test and live private certificates using this naming convention (if you want Trustly to load them automatically but you can use different path and names):

    certs/trustly/test.merchant.private.pem
    certs/trustly/live.merchant.private.pem 

## Usage

Currently supports **Deposit**, **Refund**, **AccountPayout**, **RegisterAccount** and **SelectAccount** api calls. Other calls can be implemented very easily.

### Api

In order to use Trustly Api, we'll need to create a **Trustly::Api::Signed**. Example:

```ruby
api = Trustly::Api::Signed.new(
	username: 'yourusername',
	password: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
)
```

Also make sure you have ENV variables for certificates. Default variables are: MERCHANT_PRIVATE_KEY for the signing key and TRUSTLY_PUBLIC_KEY for the verifying key.

```ruby
api = Trustly::Api::Signed.new({
	username: 'yourusername',
	password: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
  host: 'test.trustly.com',
  port: 443,
  is_https: true,
  private_pem: ENV.fetch('MY_PRIVATE_KEY_VAR', nil),
  public_pem: ENV.fetch('TRUSTLY_PUBLIC_KEY_VAR', nil)
})
```
## Examples of RPC calls
### Deposit call

Deposit is a straightfoward call. Only required arguments example:

```ruby
deposit = api.deposit(
	'EndUserID' => 10002,
	'MessageID' => 12349,
	'Amount' => '30.0',
	'ShopperStatement' => 'MyBrand.com',
	'Locale' => 'es_ES',
	'Country' => 'ES',
	'Currency' => 'EUR',
	'SuccessURL' => 'https://my-brand.com/thank_you.html',
	'FailURL' => 'https://my-brand.com/failure.html',
	'NotificationURL' => 'https://gateway.my-brand.com/notifications',
	'Firstname' => 'John',
	'Lastname' => 'Doe'
)
```
Optional arguments are:
- AccountID
- SuggestedMinAmount
- SuggestedMaxAmount
- IP
- TemplateURL
- URLTarget
- MobilePhone
- Email
- NationalIdentificationNumber
- UnchangeableNationalIdentificationNumber
- ShippingAddressCountry
- ShippingAddressPostalCode
- ShippingAddressLine1
- ShippingAddressLine2
- ShippingAddress
- RequestDirectDebitMandate
- ChargeAccountID
- QuickDeposit
- URLScheme
- ExternalReference
- PSPMerchant
- PSPMerchantURL
- MerchantCategoryCode
- RecipientInformation

This will return a **Trustly::Data::JSONRPCResponse**:

```ruby
> deposit.data_at('url')
=> "https://test.trustly.com/_/orderclient.php?SessionID=755ea475-dcf1-476e-ac70-07913501b34e&OrderID=4257552724&Locale=es_ES"

> deposit.data
=> {
	'orderid' => '4257552724', 
	'url'     => 'https://test.trustly.com/_/orderclient.php?SessionID=755ea475-dcf1-476e-ac70-07913501b34e&OrderID=4257552724&Locale=es_ES'
}
```

You can check if there was an error:

```ruby
> deposit.error?
=> true

> deposit.success?
=> false

> deposit.error_message
=> 'ERROR_DUPLICATE_MESSAGE_ID'
```

### Notifications

After a **deposit** or **refund** call, Trustly will send a notification to **NotificationURL**. If you are using rails the execution flow will look like this:

```ruby
def controller_action
	api = Trustly::Api::Signed.new({...}) 
	notification = Trustly::Data::JSONRPCNotificationRequest.new(notification_body: params)
	if api.verify_trustly_signed_notification(notification)
	   # do something with the notification
	   ...
	   # reply to trustly
	   response = api.notification_response(notification, success: true)
	   render text: response.to_json
	else
		render nothing: true, status: 200
	end
end
``` 

You can use **Trustly::Data::JSONRPCNotificationRequest** object to access data provided using the following methods:

```ruby
 notification.data
=> {"amount"=>"902.50", "currency"=>"EUR", "messageid"=>"98348932", "orderid"=>"87654567", "enduserid"=>"32123", "notificationid"=>"9876543456", "timestamp"=>"2010-01-20 14:42:04.675645+01", "attributes"=>{}}

> notification.method
=> "credit"

> notification.uuid
=> "258a2184-2842-b485-25ca-293525152425"

> notification.signature
=> "R9+hjuMqbsH0Ku ... S16VbzRsw=="

> notification.data_at('amount')
=> "902.50"

> notification.attribute_at('key')
=> nil
```



## Contributing

1. Fork it ( https://github.com/gapfish/trusty-client-ruby/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
