require 'chefspec'
require 'chefspec/berkshelf'
require 'ecomdev/chefspec'

module SpecHelper
  def load_expected_file (dataset)
    require 'erb'
    path = File.join(File.dirname(__FILE__), '_data', described_recipe.tr_s('::', '.'), dataset + '.expected')
    raise 'File ' + path + ' does not exists' unless File.exists?(path)
    raise 'File ' + path + ' is not readable' unless File.readable?(path)
    template = ERB.new File.new(path).read, nil, '%'
    template.result(binding)
  end
end

EcomDev::ChefSpec::Configuration.cookbook_path('spec/fixtures')

ChefSpec::Coverage.start!