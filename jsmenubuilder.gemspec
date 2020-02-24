Gem::Specification.new do |s|
  s.name = 'jsmenubuilder'
  s.version = '0.3.1'
  s.summary = 'Generates HTML based tabs using HTML, CSS, and JavaScript.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/jsmenubuilder.rb']
  s.add_runtime_dependency('rexle', '~> 1.5', '>=1.5.3')
  s.signing_key = '../privatekeys/jsmenubuilder.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/jsmenubuilder'
end
