
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "wisper_plus/version"

Gem::Specification.new do |spec|
  spec.name          = "wisper_plus"
  spec.version       = WisperPlus::VERSION
  spec.authors       = ["Ben Sharpe"]
  spec.email         = ["bsharpe@gmail.com"]

  spec.summary       = %q{Handy additions to Wisper}
  spec.description   = %q{Add ActiveRecord callback support; ActiveJob support and Automagic connection of subscriber classes to publisher models}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_dependency 'wisper', '>= 1.6'
end
