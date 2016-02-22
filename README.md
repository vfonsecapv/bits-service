# Bits Service

## pipeline

To update the pipeline use `./ci/set-pipeline.sh`

To run the pipeline the following configuration variables needs to be specified at `ci/config.yml`:
```yaml
bosh-target:
bosh-username:
bosh-password:
```

## Documentation

The sequence charts in `docs/` were generated with [websequencediagrams](https://www.websequencediagrams.com/) and can be regenerated with `rake docs/create-app.png` etc.
