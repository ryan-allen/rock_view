require 'rubygems'
require 'active_support'
require 'erb'

module CView
  
  class << self
    
    def construct(&renders)
      DSL.construct(&renders)
    end
    
  end
  
  class Template
    
    class MissingAssignException < Exception; end
    class UnexpectedAssignException < Exception; end

    class << self

      def template(erb = nil)
        if erb
          @@template||= {}
          @@template[self] = erb
        else
          for klass in superclasses_with_self
            return @@template[klass] if @@template[klass]
          end
        end
      end
      
      def resolve(path)
        path.classify.constantize
      rescue NameError
        nil
      end
      
      def superclasses_with_self
        superclass.respond_to?(:superclasses_with_self) ? [self] + superclass.superclasses_with_self : [Template]
      end
              
      def assign(name, opts = {})
        attr_accessor name; @assigns ||= []; assigns << name
        defaults[name] = opts[:default] if opts[:default]
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
      missing_assigns = self.class.assigns.select { |name| send(name).nil? }
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
      
      def load(path)
        traverse(path)
      end
      
    private

      def traverse(path, scope = nil)
        for entry in Dir.entries(path)
          next if entry[0].chr == '.'
          full_path = "#{path}#{File::SEPARATOR}#{entry}"
          if File.directory?(full_path)
            create_class(generate_scope(scope, entry))
            traverse(full_path, generate_scope(scope, entry))
          else
            handle(generate_scope(scope, entry), full_path)
          end
        end  
      end

      def generate_scope(scope, path)
        scope ? "#{scope}#{File::SEPARATOR}#{path}" : path
      end

      def handle(path, full_path)
        create_class(path)
        /(\.\w+)$/ =~ path
        case $1
        when '.rb'
          get_class(path).class_eval { eval(open(full_path, 'r') { |f| f.read }) }
        when '.rhtml'
          get_class(path).template open(full_path, 'r') { |f| f.read }
        else
          raise "Can't Handle #{$1}"
        end  
      end

      def create_class(path)
        Object.class_eval("class #{path.gsub(/\.\w+$/, '').classify} < CView::Template; end")
      end
      
      def get_class(path)
        path.gsub(/\.\w+$/, '').classify.constantize
      end
            
    end
    
  end
    
end