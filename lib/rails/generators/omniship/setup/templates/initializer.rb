file = YAML.load_file(Rails.root.join("config","omniship.yml"))
OMNISHIP_CONFIG = file[Rails.env]