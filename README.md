# Active Audit - Inspect models changes
Active Audit is an ORM extension for Ruby on Rails to track model changes. It also supports keeping record of who made the changes and why.

## Getting started
You can add it to your Gemfile like this:

```ruby
gem 'active-audit'
```

then run `bundle install` to install it.

Next, you need to run the generator:

```console
$ rails generate active_audit:install
```

## Usage

It can be used to track changes to [ActiveRecord](http://api.rubyonrails.org/classes/ActiveRecord/Base.html),
[Mongoid](http://mongoid.org/).

Auditing a model is as simple as including the **ActiveAudit::Base** module to you model like this:

```ruby
class Product < ActiveRecord::Base
  include ActiveAudit::Base
end
```

You can define options for you model auditing throw the `audit` function. It takes as arguments the attributes you want to track their changes and it can take one or more of the following options:

1. **type**: string/symbol that represent the type of the item being audited (by default its the class name in underscore style).
2. **except**: a list of model attributes not to audit changes (if it was defined with only the audited attributes will be the difference between the two but that is not recommended as it's not clear).
3. **unless**: a lambda function returns a boolean and the auditing will be cancled if it evalutaes to true or a symbol represents a name of an instance function of your model.

### Tracking Active Record association changes

1. one to many (belongs_to) assocation changes can be audited by auditing the foreign key itself.
1. many to many (belongs_to) assocation changes can be audited by adding the option **association** to the audit function.

Here is our model with a bunch of auditing options:

```ruby
class Product < ActiveRecord::Base
  include ActiveAudit::Base
  audit :price, :availability, :free_shipping, :num_items, type: :cool_product, associations: [:stores ], unless: lambda { |product| product.availabilty === :discontinued }
end
```

## Configuraton

Active Audit is extremely simple to configure. Just check the `config/initializers/auditing.rb` file. By default it will be like this:

```ruby
ActiveAudit.configure do |config|
  config.storage_adapter = :test
  #config.current_user_method = :current_user
  #config.ignored_attributes = %w(created_at updated_at)
  #config.delayed_auditing = false
  #config.job_queue = :audits
  #config.default_user = { id: 1 }
  #config.extract_user_profile = lambda { |user| { id: user.id } }
end
```

The configurations are commented out but they are active since these are the default configuration.

The available options are described in the table bellow:

| Option                 | Description                                                          |
| -----------------      | -------------------------------                                      |
| `current_user_method`  | The name of a function exists in your base controller that returns current user object (default `:current_user`).   |
| `ignored_attributes`   | A list of attribute names that will be ignored from auditing in all audited models (default `%w(created_at updated_at)`). |
| `delayed_auditing`     | Whether to use ActiveJob delayed jobs or not (default `false`).      |
| `job_queue`            | The name of the queue to push jobs into in case `delayed_auditing` is set to `true`. |
| `default_user`         | A hash containing the information of the user that will be used in case that `current_user_method` returned `nil`. |
| `extract_user_profile` | a lambda function used to extract a user profile from the user object returned by `current_user_method`. |

## Production Use

### Storage Adapters

Active Audit implements the repository pattern to save and retrieve model audits. By default it will use its `TestAdapter` to do the job which is no more than logging the audits using Rails logger. Of course that is no the behaviour you want to have on production; You can use on of the available Active Audit storage adapters: `:mongo`, `:active_record`, `:elasticsearch`.
