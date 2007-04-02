require 'erb'
require 'pathname'
require 'rock_view' # here only to raise proper exceptions (hehe not for long!)

module Rock
  module View
    
    class MissingAssignException < Exception; end
    class UnexpectedAssignException < Exception; end

    class << self
      def specify(*args, &block)
        Repo.specify(*args, &block)
      end
      
      def construct(*args, &block)
        Builder.construct(*args, &block)
      end
      
      def resolve(*args)
        Repo.resolve(*args)
      end
            
      def reset!
        Repo.reset!
      end
      
      def load(*args)
        Loader.load(*args)
      end
    end

    class Spec
      attr_reader :assigns, :template, :defaults, :expectations

      def initialize
        @template, @assigns, @defaults, @expectations = '<%= inspect %>', [], {}, {}
      end

      def template(erb = nil)
        erb ? @template = erb : @template
      end
                
      def assign(name, opts = {})
        assigns << name
        defaults[name] = opts[:default] if opts.has_key?(:default)
        expectations[name] = opts[:expects] if opts[:expects]
      end
    
      def assigns(*names)
        names.empty? ? @assigns : names.each { |name| assign name }
      end    
    end
    
    class Base
      attr_reader :spec, :assign_values, :parent, :sub_templates
      
      def initialize(spec, assign_values, parent = nil)
        @spec, @assign_values, @sub_templates = spec, assign_values, []
        if parent
          @parent = parent
          parent.sub_templates << self
        end
      end
    end
    
    module Repo
      class << self
        def specify(path, &config)
          @map[path] = Template.clone
          @map[path].class_eval(&config)
          @map[path]
        end
        
        def resolve(path)
          @map[path]
        end
        
        def reset!
          @map = {}
        end
      end
      reset!
    end; Repository = Repo
      
    class Template
    
      class << self
      
        # not cloning these instance vars was causing problems!
        def clone
          the_clone = super
          the_clone.instance_eval do
            @template = @template.clone if @template
            @assigns = @assigns.clone if @assigns
            @defaults = @defaults.clone if @defaults
            @expectations = @expectations.clone if @expectations
          end
          the_clone
        end
        
        def template(erb = nil)
          erb ? @template = erb : @template
        end
      
        def resolve(path)
          Repo.resolve(path)
        end
            
        def superclasses_with_self
          [self, Template]
        end
              
        def assign(name, opts = {})
          attr_accessor name; @assigns ||= []; assigns << name
          defaults[name] = opts[:default] if opts.has_key?(:default)
          expectations[name] = opts[:expects] if opts[:expects]
        end
      
        def assigns(*names)
          names.empty? ? (@assigns ||= []) : names.each { |name| assign name }
        end
      
        def defaults; @defaults ||= {}; end
        def expectations; @expectations ||= {}; end
      
      end
    
      attr_accessor :parent
      attr_reader :sub_templates
    
      template '<%= inspect %>'
    
      def initialize(assigns = {}, parent = nil)
        self.parent = parent
        self.class.defaults.each { |name, value| send "#{name}=", value }
        assigns.each { |name, value| send "#{name}=", value }
        @sub_templates = []
      end
    
      def template(erb = nil)
        @template ? @template : self.class.template
      end
    
      def template=(erb)
        @template = erb
      end
    
      def method_missing(method, *args)
        parent ? parent.send(method, *args) : super
      end
    
      def render(path, assigns = {}, &erb)
        if klass = self.class.resolve(path)
          if erb
            #
            # oh my god this is a huge hack, sub templates in this context have
            # no access to uh, parents or something...
            #
            template = klass.new(assigns)
            split = Template.new
            split.template = '##SPLIT##'
            split.parent = template; template.sub_templates << split
            rendered_template = template.to_s
            top, bottom = rendered_template.split('##SPLIT##')
            eval("_erbout", erb.binding).concat(top)
            erb.call()
            eval("_erbout", erb.binding).concat(bottom)
          else
            #
            # this is the plain old good rendering method :D
            #
            template = klass.new(assigns)
            template.parent = self
            template.to_s
          end
        else
          raise "Cannot resolve '#{path}'"
        end
      end
    
      def render_sub_templates
        sub_templates.collect { |template| template.to_s }.join
      end
    
      def to_s
        missing_assigns = self.class.assigns.select { |name| send(name).nil? and not self.class.defaults.has_key?(name) }
        unexpected_assigns = self.class.expectations.select { |name, values| !values.include?(send(name)) }
        if not missing_assigns.empty?
          raise MissingAssignException.new("#{self.class} was missing the following assigns: #{missing_assigns.join(', ')}")        
        elsif not unexpected_assigns.empty?
          raise UnexpectedAssignException.new("Aie!")        
        else
          erb(template)
        end
      end
    
    protected
  
      def erb(str)
        ERB.new(str, nil, '<>').result(binding)
      end
    
    end
  
    module Builder
              
      class << self
      
        def construct(&renders)
          @scope = [Repo.specify('Construct Context') { template '<%= render_sub_templates %>' }.new]
          instance_eval(&renders)
          @scope.first.to_s
        end
      
        def render(path, assigns = {}, &renders)
          template = Template.resolve(path).new(assigns, @scope.last)
          # THIS LINE WILL BE CHANGED BECAUSE IT WILL HANDLE ITSELF
          template.parent = @scope.last; @scope.last.sub_templates << template
          if renders
            @scope << template
            instance_eval(&renders)
            @scope.pop
          end
        end
      
      end
    
    end
  
    class Loader
    
      class << self
      
        def load(path, scope = nil)
          traverse(path, scope)
        end
      
      private

        def traverse(path, scope = nil)
          for entry in Dir.entries(path)
            next if entry[0].chr == '.'
            full_path = "#{path}/#{entry}"
            if File.directory?(full_path)
              traverse(full_path, generate_scope(scope, entry))
            else
              handle(generate_scope(scope, entry), full_path)
            end
          end  
        end

        def generate_scope(scope, path)
          scope ? "#{scope}/#{path}" : path
        end

        def handle(path, full_path)
          /(\.\w+)$/ =~ path
          case $1
          when '.rb'
            template_path = path[0..-4] # take off the .rb
            Repo.specify(template_path) { eval(Pathname.new(full_path).open('r') { |f| f.read }) }
          else
            # do something here to complain about unhandled filetypes
          end  
        end
            
      end
    
    end
    
  end
  
end