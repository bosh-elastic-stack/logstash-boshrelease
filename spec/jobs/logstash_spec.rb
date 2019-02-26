require 'rspec'
require 'yaml'
require 'bosh/template/test'

describe 'logstash job' do
  let(:release) { Bosh::Template::Test::ReleaseDir.new(File.join(File.dirname(__FILE__), '../..')) }
  let(:job) { release.job('logstash') }

  describe 'logstash.yml.template' do
    let(:template) { job.template('config/logstash.yml.template') }
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
end 
