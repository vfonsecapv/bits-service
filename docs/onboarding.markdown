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

# Undecided

* Do we use the public Slack or a mailing list?
* Do we need a private Slack channel or mailing list in addition to the public one?
