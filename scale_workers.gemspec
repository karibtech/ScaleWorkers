# coding: utf-8

Gem::Specification.new do |spec|
  spec.add_dependency 'delayed_job_active_record', ['4.0.2']
  spec.add_dependency 'usagewatch', ['0.0.7']
  spec.authors        = ['Karthick Shankar']
  spec.description    = 'Auto scaling job workers for delayed_job_active_record'
  spec.summary        = 'Stop worrying about scaling job workers'
  spec.email          = ['karibtech@gmail.com']
  spec.files          = %w[scale_workers.gemspec]
  spec.files         += Dir.glob('lib/**/*.rb')
  spec.licenses       = ['MIT']
  spec.name           = 'scale_workers'
  spec.require_paths  = ['lib']
  spec.version        = '0.0.1'
  spec.add_development_dependency 'minitest', ['~> 3.1']
  spec.add_development_dependency 'mocha', ['1.0.0']
  spec.test_files     = Dir.glob('test/**/*.rb')
end
