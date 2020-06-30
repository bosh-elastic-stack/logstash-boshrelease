require 'rspec'
require 'yaml'
require 'bosh/template/test'

describe 'logstash job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('logstash') }

  describe 'logstash.yml' do
    let(:template) { job.template('config/logstash.yml.tmpl') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test'
            },
          }
        )
      ] }

    it 'configures defaults successfully' do
      config = YAML.safe_load(template.render({}, consumes: links))
      expect(config['node.name']).to eq('me/0')
    end

    it 'configures elasticsearch.config_options' do
      config = YAML.safe_load(template.render({'logstash' => {
        'config_options' => {
            'log' => {
              'level' => 'debug'
            },
          }
        }}, consumes: links))
      expect(config['log']['level']).to eq('debug')
    end
  end


  describe 'pipelines.yml' do
    let(:template) { job.template('config/pipelines.yml') }
    let(:prestart) { job.template('bin/pre-start') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test'
            },
          }
        )
      ] }

    it 'configures defaults successfully' do
      config = YAML.safe_load(template.render({}, consumes: links))
      expect(config.to_s).to eq('')
    end

    it 'configures logstash.pipelines' do
      props = {'logstash' => {
        'pipelines' => [
          {
            'name' => 'test',
            'params' => {
              'queue.type' => 'persisted',
              'pipeline.workers' => '3'
            },
            'config' => {
              'tcp' => 'input { tcp { port => 5514 } } output { stdout { codec => json_lines } }'
            }
          }
        ]}}
      config = YAML.safe_load(template.render(props, consumes: links))
      expect(config[0]['pipeline.id']).to eq('test')
      expect(config[0]['path.config']).to eq('/var/vcap/jobs/logstash/config/conf.d/test/*.conf')
      expect(config[0]['queue.type']).to eq('persisted')
      expect(config[0]['pipeline.workers']).to eq(3)

      script = prestart.render(props, consumes: links)
      expect(script).to include('mkdir -p /var/vcap/jobs/logstash/config/conf.d/test')
      expect(script).to include("cat <<'EOF' > /var/vcap/jobs/logstash/config/conf.d/test/tcp.conf")
      expect(script).to include('input { tcp { port => 5514 } } output { stdout { codec => json_lines } }')
    end

    it 'configures multiple logstash.pipelines' do
      props = {'logstash' => {
        'pipelines' => [
          {
            'name' => 'tcp',
            'params' => {
              'queue.type' => 'persisted',
              'pipeline.workers' => '3'
            },
            'config' => {
              'tcp1' => 'input { tcp { port => 5514 } } output { stdout { codec => json_lines } }',
              'tcp2' => 'input { tcp { port => 5515 } } output { stdout { codec => json_lines } }'
            }
          },
          {
            'name' => 'file',
            'config' => {
              'file' => 'input { file { path => "/path/to/access.log" } } output { stdout { codec => json_lines } }'
            }
          }
        ]}}
      config = YAML.safe_load(template.render(props, consumes: links))
      expect(config[0]['pipeline.id']).to eq('tcp')
      expect(config[0]['path.config']).to eq('/var/vcap/jobs/logstash/config/conf.d/tcp/*.conf')
      expect(config[0]['queue.type']).to eq('persisted')
      expect(config[0]['pipeline.workers']).to eq(3)

      script = prestart.render(props, consumes: links)
      expect(script).to include('mkdir -p /var/vcap/jobs/logstash/config/conf.d/tcp')
      expect(script).to include('mkdir -p /var/vcap/jobs/logstash/config/conf.d/file')
      expect(script).to include("cat <<'EOF' > /var/vcap/jobs/logstash/config/conf.d/tcp/tcp1.conf")
      expect(script).to include("cat <<'EOF' > /var/vcap/jobs/logstash/config/conf.d/tcp/tcp2.conf")
      expect(script).to include("cat <<'EOF' > /var/vcap/jobs/logstash/config/conf.d/file/file.conf")
      expect(script).to include('input { tcp { port => 5514 } } output { stdout { codec => json_lines } }')
      expect(script).to include('input { tcp { port => 5515 } } output { stdout { codec => json_lines } }')
      expect(script).to include('input { file { path => "/path/to/access.log" } } output { stdout { codec => json_lines } }')
    end
  end


  describe 'pre-start.sh' do
    let(:template) { job.template('bin/pre-start') }
    let(:links) { [
        Bosh::Template::Test::Link.new(
          name: 'elasticsearch',
          instances: [Bosh::Template::Test::LinkInstance.new(address: '10.0.8.2')],
          properties: {
            'elasticsearch'=> {
              'cluster_name' => 'test'
            },
          }
        )
      ] }

    it 'sets plugins properties' do
      prestart = template.render({'logstash' => {
        'plugins' => [
          { 'logstash-input-cloudwatch_logs': 'logstash-input-cloudwatch_logs' },
          { 'logstash-output-kafka': 'logstash-output-kafka' },
        ],
        'plugin_install_opts' => ['--development']
      }}, consumes: links).strip
      expect(prestart).to include('logstash-plugin install --development "logstash-input-cloudwatch_logs"')
      expect(prestart).to include('logstash-plugin install --development "logstash-output-kafka"')
    end
  end
end 
