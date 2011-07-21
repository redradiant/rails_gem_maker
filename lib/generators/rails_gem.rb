require 'rails/generators/named_base'
require 'pathname'

module RailsGem
  
  module Paths
    
    class GemFileManifest < Array
      attr_accessor :rails_root, :destination_path, :template_root
      
      def add(*other)
        paths = other.flatten.compact.uniq.collect do |p|
          gf = GemFile.new(p)
          gf.rails_root = rails_root
          gf.destination_root = destination_root
          gf.template_root = template_root
          gf
        end
        
        self.concat(paths)
        self
      end
      
    end
    
    # A file that will go in the gem.
    class GemFile < Pathname
      
      attr_accessor :rails_root, :destination_root, :template_root
      
      def initialize(*args, &block)
        @rails_root ||= (Rails.root rescue Dir.pwd)
        @destination_root ||= Pathname('vendor/gems')
        @template_root ||= Pathname(Dir.pwd + '/../generators/templates/')
      end
      
      # Do we have a Rails root?
      def rails_root?
        !@rails_root.blank? && @rails_root.directory?
      end
      
      # Strip the rails path off a path
      def rails_relative(path=nil)
        rails_root? ? Pathname.new(path || self.to_s).relative_path_from(@rails_root) : path
      end
      
      def relative_path
        relative? ? self : Pathname(self.relative_path_from(destination_root || rails_root))
      end
      
      def destination_root
        rails_root? && @destination_root && FileUtils.mkdir_p(@destination_root)
        Pathname.new(@destination_root)
      end
      
      def template_root
        @template_root && Pathname.new(@template_root)
      end
      
      def template_file
        @template_file ||= (template_root.join(rails_relative(self.to_s)).sub_ext(".tt") rescue nil)
      end
      
      def has_template?
        template_file.file? rescue false
      end
      
      def has_template_root?
        template_root.exist? && template_root.directory?
      end
    end
    
    def tpath(path)
      paths = relative_path_from(gem_dir(path))
    end
    
    paths = GemFileManifest.new
    
    
    paths += %w{README Rakefile}
    
    paths +='lib/', 'lib/#{name}.rb']; end
    
    def railtie; tpath 'lib/#{name}/railtie.rb'; end

    def engine; tpath 'lib/#{name}/engine.rb'; end
     
    def rails_rake_tasks(extra=nil); tpath ['lib/#{name}/tasks/#{name}.rake'].concat(extra); end
    
    def app(*path)
      path.flatten.uniq.collect { |f| 'app/#{f}' }
    end
  
  module Generators
    class Base < Rails::Generators::Base #:nodoc:

      desc "Generate a new gem designed for use in a Rails 3+ application and optionally install it."
      namespace "rails_gem"
      generator_name "new"
      
      class_option :test_framework, :default => :test_unit
      
      
      # The dir where the gem is going
      def gem_dir(join=nil)
        if join
          File.join(gem_dir, join)
        else
          "vendor/plugins/#{file_name}"
        end
      end
      
      protected
      

      def create_tasks
        
        def create_skeleton(components = nil, &config)
          exclude = (exclude.kind_of?(Array) ? exclude : [exclude]).compact.uniq.map { |e| e.to_s.underscore }
          dirs = %w{lib test lib/tasks } - exclude
        directory 'lib/tasks', gem_dir('lib/tasks')
        return unless options[:tasks]
        template('templates/rake_task.tt', "#{name}/lib/#{name}.rb")
      end
      

      
      def self.source_root
        @_simple_form_source_root ||= File.expand_path(File.join(File.dirname(__FILE__), 'simple_form', generator_name, 'templates'))
      end
      protected

      def format
        :html
      end

      def handler
        :erb
      end

      def filename_with_extensions(name)
        [name, format, handler].compact.join(".")
      end
      
      def template_filename_with_extensions(name)
        [name, format, handler, :erb].compact.join(".")
      end
    end
  end
end


class Newgem < Thor::Group
  include Thor::Actions

  # Define arguments and options
  argument :name
  class_option :test_framework, :default => :test_unit

  def self.source_root
    File.dirname(__FILE__)
  end

  def create_lib_file
    template('templates/newgem.tt', "#{name}/lib/#{name}.rb")
  end

  def create_test_file
    test = options[:test_framework] == "rspec" ? :spec : :test
    create_file "#{name}/#{test}/#{name}_#{test}.rb"
  end

  def copy_licence
    if yes?("Use MIT license?")
      # Make a copy of the MITLICENSE file at the source root
      copy_file "MITLICENSE", "#{name}/MITLICENSE"
    else
      say "Shame on you…", :red
    end
  end
end
