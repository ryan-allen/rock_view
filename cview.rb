require 'erb'
require 'pathname'
require 'rock_view' # here only to raise proper exceptions

module CView
  
  class << self
    
    def construct(&renders)
      Builder.construct(&renders)
    end
    
    def render_scope=(scope)
      Template.render_scope = scope
    end
    
    def reset!
      Repository.reset!
    end
    
  end
  
  module Builder
    class << self
      def construct(&renders)
        DSL.construct(&renders)
      end
    end
  end
  
  class Spec
    attr_reader :assigns, :template, :defaults, :expectations
    def initialize(template, assigns, defaults, expectations)
      @template = template
      @assigns = assigns
      @defaults = defaults
      @expectations = expectations
    end
  end
  
  class View
    attr_reader :spec, :assign_values, :parent, :sub_templates
    def initialize(spec, assign_values, parent = nil)
      @spec = spec
      @assign_values = @assign_values
      @sub_templates = []
      if parent
        @parent = parent
        parent.sub_templates << self
      end
    end
    def to_s
    end
  end
  
  module Repository
    class << self
      def reset!
        @specs = {}
      end
      def resolve(path)
        @specs[path]
      end
    end
    reset!
  end
  
  class Template
    
    class << self
      
      def reset!
        @@template_map = {}
        @@render_scope = nil
        @@template = {}
      end
      
      def render_scope=(scope)
        @@render_scope = scope
      end

      def template(erb = nil)
        if erb
          @@template[self] = erb
        else
          for klass in superclasses_with_self
            return @@template[klass] if @@template[klass]
          end
        end
      end
      
      def resolve(path)
        @@render_scope ? @@template_map["#{@@render_scope}/#{path}"] : @@template_map[path]
      end
      
      def create(path, &blk)
        @@template_map[path] = self.clone
        @@template_map[path].instance_eval(&blk) if blk
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
    
    reset!
    
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
        raise Rock::View::MissingAssignException.new("#{self.class} was missing the following assigns: #{missing_assigns.join(', ')}")        
      elsif not unexpected_assigns.empty?
        raise Rock::View::UnexpectedAssignException.new("Aie!")        
      else
        erb(template)
      end
    end
    
  protected
  
    def erb(str)
      ERB.new(str, nil, '<>').result(binding)
    end
    
  end
  
  class DSL < Template
        
    template '<%= render_sub_templates %>'
        
    class << self
      
      def construct(&renders)
        @scope = [self.new]
        instance_eval(&renders)
        @scope.first.to_s
      end
      
      def render(path, assigns = {}, &renders)
        template = Template.resolve(path).new(assigns, @scope.last)
        template.parent = @scope.last; @scope.last.sub_templates << template # duplication here?
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
            create_class(generate_scope(scope, entry))
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
          template_path = path[0..-4]
          create_class(template_path)
          get_class(template_path).class_eval { eval(Pathname.new(full_path).open('r') { |f| f.read }) }
        else
          # raise "Can't Handle: #{$1.inspect} #{full_path.inspect}"
        end  
      end

      def create_class(path)
        Template.create(path)
      end
      
      def get_class(path)
        Template.resolve(path)
      end
            
    end
    
  end
    
end