module Omniship
	module Generators
		class SetupGenerator < Rails::Generators::Base
			desc 'Creates a Omniship gem configuration file at config/omniship.yml, and an initializer at config/initializers/omniship.rb'

			def self.source_root
				@_omniship_source_root ||= File.expand_path("../templates", __FILE__)
			end

			def create_config_file
				template 'omniship.yml', File.join('config', 'omniship.yml')
			end

			def create_initializer_file
				template 'initializer.rb', File.join('config', 'initializers', 'omniship.rb')
			end
		end
	end
end