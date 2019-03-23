## Logstash BOSH Release

Use [elastic-stack-bosh-deployment](https://github.com/bosh-elastic-stack/elastic-stack-bosh-deployment) to deploy Elastic Stack.

**ℹ️ Important ℹ️**

Since 0.9.0, logstash bosh release comes with [the pure Apache 2.0 licensed distribution](https://www.elastic.co/downloads/logstash-oss).
Please do not use previous versions.
If you want to use X-Pack features, download [Elastic License licensed distribution](https://www.elastic.co/jp/downloads/logstash) and build the bosh release with it by yourself. You can use [a prepared concourse task](#build-your-own-bosh-release-with-x-pack-by-concourse). 

### Configure multipe pipelines

You can configure [multipe pipelines](https://www.elastic.co/guide/en/logstash/current/multiple-pipelines.html) by specifiying `logstash.pipelines` property.

Example: `logstash-pipelines.yml`

```yaml
- type: replace
  path: /instance_groups/name=logstash/properties/logstash/pipelines?
  value:
  - name: foo
    config:
      foo: ((foo.conf))
  - name: bar
    config:
      input: ((bar-input.conf))
      filter1: ((bar-filter1.conf))
      filter1: ((bar-filter2.conf))
      output: ((bar-output.conf))
```

```
bosh -d logstash deploy manifest/logstash.yml \
  --var-file foo.conf=pipelines/foo.conf \
  --var-file bar-input.conf=pipelines/bar-input.conf \
  --var-file bar-filter1.conf=pipelines/bar-filter1.conf \
  --var-file bar-filter2.conf=pipelines/bar-filter2.conf \
  --var-file bar-output.conf=pipelines/bar-output.conf \
  --no-redact
```

This properity is compatible with [cf-logging-boshrelease](https://github.com/SpringerPE/cf-logging-boshrelease/tree/master/manifest/operations/pipelines)

### Build your own bosh release with X-Pack by Concourse

logstash boshrelease does not include X-Pack since it uses the pure Apache 2.0 licensed distribution.
You can use [create-el-bosh-release.yml](ci/create-el-bosh-release.yml) to build your own bosh release with Elastic License licensed distribution.

Here is a sample pipeline:

```yaml
resources:
- name: repo
  type: git
  source:
    uri: https://github.com/bosh-elastic-stack/logstash-boshrelease.git
- name: gh-release
  type: github-release
  source:
    user: bosh-elastic-stack
    repository: logstash-boshrelease
    access_token: ((github-access-token))
- name: release
  type: s3
  source:
    bucket: your-bucket
    regexp: logstash-boshrelease-(.*).tgz
    access_key_id: ((s3-access-key-id))
    secret_access_key: ((s3-secret-access-key))

jobs:
- name: create-el-bosh-release
  plan:
  - aggregate:
    - get: gh-release
      trigger: true
      params:
        include_source_tarball: true
    - get: repo
  - task: create-release
    params:
      VERSION_SUFFIX: "_el"
    file: repo/ci/create-el-bosh-release.yml
  - put: release
    params:
      file: bosh-releases/logstash-boshrelease-*.tgz
```

If you want to upload the release directly, use the following pipeline

```yaml
resources:
- name: repo
  type: git
  source:
    uri: https://github.com/bosh-elastic-stack/logstash-boshrelease.git
- name: gh-release
  type: github-release
  source:
    user: bosh-elastic-stack
    repository: logstash-boshrelease
    access_token: ((github-access-token))

jobs:
- name: create-el-bosh-release
  plan:
  - aggregate:
    - get: gh-release
      trigger: true
      params:
        include_source_tarball: true
    - get: repo
  - task: create-release
    params:
      VERSION_SUFFIX: "_el"
    file: repo/ci/create-el-bosh-release.yml
  - task: upload-release
    params:
      BOSH_CLIENT: ((bosh-client))
      BOSH_ENVIRONMENT: ((bosh-environment))
      BOSH_CLIENT_SECRET: ((bosh-client-secret))
      BOSH_CA_CERT: ((bosh-ca-cert))
    config:
      platform: linux
      image_resource:
        type: registry-image
        source:
          repository: bosh/main-bosh-docker
      inputs:
      - name: bosh-releases
      outputs:
      - name: bosh-releases
      run:
        path: bash
        args:
        - -c
        - |
          set -e
          bosh upload-release bosh-releases/*.tgz
```

![image](https://user-images.githubusercontent.com/106908/54048835-33fa3b00-421e-11e9-84f7-1d0225a4f114.png)

### How to build this bosh release for development

#### Build and deploy this bosh release

```
bosh sync-blobs
bosh create-release --name=logstash --force --timestamp-version --tarball=/tmp/logstash-boshrelease.tgz && bosh upload-release /tmp/logstash-boshrelease.tgz
bosh -d logstash deploy manifest/logstash.yml --var-file logstash.conf=manifest/logstash.conf --no-redact
```

#### How to test spec files

```
bundle install
bundle exec rspec spec/jobs/*_spec.rb
```
