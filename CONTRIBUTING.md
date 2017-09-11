# Contributing

## Use the issues tracker

### Bugs
Make sure the bug is not a feature. Check the [Manual](https://robokopp.github.io/toast/) first. 

### Feature Requests
Make sure it's not already included. Check the [Manual](https://robokopp.github.io/toast/) first.

I am open for discussion. Ther more you contribute (pull requests) the better. 

## Testing

The `/test` directory contains a test suite and a `Vagrantfile` to setup a testing environemnt. 

*Every pull request needs to include proper test cases for the new feature or bug fix.*

You need Vagrant, VirtualBox and Ansible for setting it up. To run the test suite

    cd ./test
    vagrant up
    (wait...)
    ...
    TASK [debug] ***********************************************************************************
    ok: [default] => {
      "msg": "All tests passed successfully."
    }
    
This installs a Fedora-25 and Ruby on Rails apps containing models, toast-configuations and integration tests. For there two instances of the test apps for the 5.0 and the 5.1 series. I am going to add the minor releases as they are published. 






