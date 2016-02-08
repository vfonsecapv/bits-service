# Onboarding a new Team Member

* get access to the [tracker](https://www.pivotaltracker.com/n/projects/1406862)
* add team member to a group with access to the [repo](https://github.com/cloudfoundry-incubator/bits-service)
* Create a SL account
* Create a [new VPN password](https://control.softlayer.com/account/user/profile)
* Set up the [VPN client](http://knowledgelayer.softlayer.com/procedure/ssl-vpn-mac-os-x-1010)

# BOSH

* Bring up the VPN
* Point BOSH cli at the director:

    ```
    bosh target https://10.155.248.165:25555
    ```

* If the IP address doesn't match, check the [device list](https://control.softlayer.com/devices)

# Concourse

```
# name the target 'flintstone' and login
fly --target flintstone login --concourse-url 'http://10.155.248.166:8080'

# if the auth expired, re-login using the previously named target
fly -t flintstone login

# create or update a pipeline from yaml file
fly -t flintstone set-pipeline -p test-exists -c test-exists.yml

# destroy a pipeline
fly -t flintstone destroy-pipeline -p test-exists

# hijack into a job
fly intercept -t flintstone --job bits-service/run-tests

# run a single task with local changes without having to commit to git before
fly execute -t flintstone --config ci/tasks/run-tests.yml --input=git-bits-service=.
```

# Undecided

* Do we use the public Slack or a mailing list?
* Do we need a private Slack channel or mailing list in addition to the public one?
