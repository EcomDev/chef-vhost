require 'chefspec'
require 'chefspec/berkshelf'
require 'chefspec/cacher'
require 'erb'

module SpecHelper
  def stub_include (additional_recipes = [])
    # Don't worry about external cookbook dependencies
    allow_any_instance_of(Chef::Cookbook::Metadata).to receive(:depends)

    # Test each recipe in isolation, regardless of includes
    @included_recipes = []
    allow_any_instance_of(Chef::RunContext).to receive(:loaded_recipe?).and_return(false)

    allow_any_instance_of(Chef::RunContext).to receive(:include_recipe).with(described_recipe).and_call_original

    allow_any_instance_of(Chef::RunContext).to receive(:include_recipe) do |run_context, recipe_name|
      if recipe_name.is_a?(String)
        allow_any_instance_of(Chef::RunContext).to receive(:loaded_recipe?).with(recipe_name).and_return(true)
        @included_recipes.push(recipe_name)
        if additional_recipes.include?(recipe_name)
          run_context.load_recipe(recipe_name)
        end
      else
        recipe_name.flatten.each do |sub_recipe_name|
          run_context.include_recipe(sub_recipe_name)
        end
      end

      @included_recipes
    end

    allow_any_instance_of(Chef::RunContext).to receive(:loaded_recipes).and_return(@included_recipes)
  end

  # @return [self]
  def converge
    chef_run.converge(described_recipe) do
      yield chef_run.node, chef_run if block_given?
    end

    self
  end

  def load_expected_file (dataset)
    path = File.join(File.dirname(__FILE__), '_data', described_recipe.tr_s('::', '.'), dataset + '.expected')
    raise 'File ' + path + ' does not exists' unless File.exists?(path)
    raise 'File ' + path + ' is not readable' unless File.readable?(path)
    template = ERB.new File.new(path).read, nil, '%'
    template.result(binding)
  end

  # @return [ChefSpec::Runner]
  def converged
    if chef_run.compiling?
      converge do |node, runner|
        yield node, runner if block_given?
      end
    end

    chef_run
  end
end

class SpecPlatforms
  def self.versions
    {
        'ubuntu' => ['10.04', '12.04', '13.10', '14.04'],
        'debian' => ['6.0.5', '7.2', '7.4'],
        'freebsd' => ['9.2'],
        'centos' => ['5.8','6.4', '6.5'],
        'redhat' => ['5.6', '6.3', '6.4'],
        'fedora' => ['18', '19', '20']
    }
  end

  def self.filtered(latest=false, platforms = [])
    os_hash = Hash.new
    all_os = versions

    if platforms.count == 0
       all_os.keys.each { |key| platforms.push(key) }
    end

    platforms.each do |platform|
      if all_os.has_key?(platform)
        if latest
          os_hash[platform] = Array(all_os[platform]).last
        else
          os_hash[platform] = all_os[platform]
        end
      end
    end
    os_hash
  end

  def self.platform_families(latest=true)
    self.filtered(latest, %w(fedora redhat debian))
  end
end

ChefSpec::Coverage.start!