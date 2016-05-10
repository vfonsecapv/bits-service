# Onboarding a new Team Member

* get access to the [tracker](https://www.pivotaltracker.com/n/projects/1406862)
* add team member to a group with access to the [repo](https://github.com/cloudfoundry-incubator/bits-service)
* Create a SL account
* Create a [new VPN password](https://control.softlayer.com/account/user/profile)
* Set up the [VPN client](http://knowledgelayer.softlayer.com/procedure/ssl-vpn-mac-os-x-1010)
* Get access to shared Lastpass folder

# Team Communication

* [#flintstone](https://cloudfoundry.slack.com/messages/flintstone/)
* [Board](https://docs.google.com/document/d/14iuA0uaxmda1Ug1Vmwh7Qd3v65IWhsiP7buqRwEK4v8/)

# BOSH

* Bring up the VPN
* Point BOSH cli at the director:

    ```
    bosh target https://10.155.248.165:25555
    ```

* If the IP address doesn't match, check the [device list](https://control.softlayer.com/devices)

* To access the SL bosh-lite director from your working station:

    ```
    ssh -L 25555:192.168.50.4:25555 root@10.155.248.181
    # And in another terminal:
    bosh target https://localhost:25555
    ```

# Concourse

Our pipeline is public at [flintstone.ci.cf-app.com](https://flintstone.ci.cf-app.com).

```
# name the target 'flintstone' and login with password from the Lastpass CLI.
fly --target flintstone login --concourse-url http://10.155.248.166:8080 --user admin --password $(lpass show concourse --password)

# if the auth expired, re-login using the previously named target
fly -t flintstone login

# create or update a pipeline from yaml file
fly -t flintstone set-pipeline -p test-exists -c test-exists.yml

# destroy a pipeline
fly -t flintstone destroy-pipeline -p test-exists

# hijack into a job
fly intercept -t flintstone --job bits-service/run-tests

# let fly offer which container to hijack. Also, use sh instead of bash for busybox-based containers.
fly intercept -t flintstone sh

# run a single task with local changes without having to commit to git before
fly execute -t flintstone --config ci/tasks/run-tests.yml --input=git-bits-service=.

# same, but with two inputs
fly execute -t flintstone --config ci/tasks/upload-to-object-storage.yml --input=git-bits-service-release=. --input=releases=dev_releases/bits-service
```
