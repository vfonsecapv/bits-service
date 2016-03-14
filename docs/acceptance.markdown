# Acceptance

The acceptance environment is located at [this softlayer box](https://control.softlayer.com/devices/details/889955).
It's a bosh-light environment that's deployed manually.

bosh and cf clients should be configured

The pipeline is pushing every release tgz and manifest to an object storage, all files are uploaded in the `upload-to-object-storage` task, check the list bellow to see where each file gets uploaded:

* bits-service-release tgz: https://flintstone.ci.cf-app.com/pipelines/bits-service/jobs/create-and-upload-release
* bits-service-release manifest: https://flintstone.ci.cf-app.com/pipelines/bits-service/jobs/deploy-with-LOCAL
* cf-release tgz: https://flintstone.ci.cf-app.com/pipelines/bits-service/jobs/create-and-deploy-CF
* cf-release manifest: https://flintstone.ci.cf-app.com/pipelines/bits-service/jobs/turn-BITS-flag-ON

All the manifests have no credentials except for the bosh/cf default ones. They are using local storage as fog configuration.

** Note: when delivering a story, always remember to link to the correct release and manifest download urls**

## Standalone Bits-Service-Release

You need to download the bits-service-release and the manifest from the `upload-to-object-storage` task:

```
wget 'https://lon02.objectstorage.softlayer.net:443/v1/AUTH_..../bits-service-release/1.0.0%2Ddev.88/bits%2Dservice%2D1.0.0%2Ddev.88.tgz' -O release.tgz
wget 'https://lon02.objectstorage.softlayer.net:443/v1/AUTH_.../bits-service-release/1.0.0%2Ddev.88/manifest.yml' -O manifest.yml
```

**Note: it's important that the BITS-Service release and the manifest versions are the same, to ensure compatibility.**

Upload the release, target the manifest and deploy to bosh:

```
bosh upload release release.tgz
bosh deployment manifest.yml
bosh deploy
```

To check the bits-service vm ip:

```
bosh vms bits-service-local
```


## Cloudfoundry + Bits-Service-Release

You need to download the bits-service-release, cf-release and the manifest from the `upload-to-object-storage` task:

```
wget 'https://lon02.objectstorage.softlayer.net:443/v1/AUTH_..../bits-service-release/1.0.0%2Ddev.88/bits%2Dservice%2D1.0.0%2Ddev.88.tgz' -O bits-service-release.tgz
wget 'https://lon02.objectstorage.softlayer.net:443/v1/AUTH_..../cf-release/1.0.0%2Ddev.33/cf-release%2D1.0.0%2Ddev.33.tgz' -O cf-release.tgz


wget 'https://lon02.objectstorage.softlayer.net:443/v1/AUTH_.../cf-release/1.0.0%2Ddev.33/manifest.yml' -O manifest.yml
```
**Note: it's important that the CF-release and the manifest versions are the same, to ensure compatibility.**

Upload the release, target the manifest and deploy to bosh:

```
bosh upload release bits-service-release.tgz
bosh upload release cf-release.tgz
bosh deployment manifest.yml
bosh deploy
```

To check the bits-service vm ip:

```
bosh vms cf-warden
```
