require 'rails/generators/named_base'
require 'pathname'
require 'fileutils'

module RailsGem

  module StringExtensions
    def to_gf(manifest = nil)      
  end

  module Paths
    class GemFileManifest < Array
      attr_accessor :rails_root, :destination_path, :template_root
      
      def add(*other)
        self.concat(other.flatten.compact.uniq.collect { |p| GemFile.new(p).inherit_from_manifest(self) })
        self
      end
    end

    # A file that will go in the gem.
    class GemFile < Pathname
      
      attr_accessor :rails_root, :destination_root, :template_root
      
      def initialize(*args, &block)
        @rails_root ||= GemFile.new(Rails.root rescue Dir.pwd)
        @destination_root ||= GemFile.new('vendor/gems')
        @template_root ||= GemFile.new(Dir.pwd + '/../generators/templates/')
      end
      
      def inherit_from_manifest(m)
        @rails_root = m.rails_root
        @destination_root = m.destination_root
        @template_root = m.template_root
        self
      end

      # Do we have a Rails root?
      def rails_root?
        !@rails_root.blank? && @rails_root.directory?
      end
      
      # Strip the rails path off a path
      def rails_relative(path=nil)
        rails_root? ? GemFile.new(path || self.to_s).relative_path_from(@rails_root) : path
      end
      
      def relative_path
        relative? ? self : GemFile.new(self.relative_path_from(destination_root || rails_root))
      end
      
      def destination_root
        rails_root? && @destination_root && FileUtils.mkdir_p(@destination_root)
        GemFile.new(@destination_root)
      end

			def destination_path
				destination_root.join(relative_path)
			end
      
      def template_root
        @template_root && GemFile.new(@template_root)
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

    end # module GemFile    
  end # module Paths 
end #module GemFile

Object.class_eval { include RailsGem::StringExtensions }

raise "Could not extend Object" unless "hi".respond_to?(:to_gf)
