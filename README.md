## Logstash BOSH Release

Use [elastic-stack-bosh-deployment](https://github.com/bosh-elastic-stack/elastic-stack-bosh-deployment) to deploy Elastic Stack.

### How to build this bosh release for development

#### Build and deploy this bosh release

```
bosh sync-blobs
bosh create-release --name=logstash --force --timestamp-version --tarball=/tmp/logstash-boshrelease.tgz && bosh upload-release /tmp/logstash-boshrelease.tgz
logstash deploy manifest/logstash.yml --var-file logstash.conf=manifest/logstash.conf --no-redact
```

#### How to test spec files

```
bundle install
bundle exec rspec spec/jobs/*_spec.rb
```