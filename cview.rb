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

    class << self

      def template=(erb)
        @@template||= {}
        @@template[self] = erb
      end

      def template
        for klass in superclasses_with_self
          return @@template[klass] if @@template[klass]
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
      
    end
    
    attr_accessor :parent
    attr_reader :sub_templates
    
    self.template = '<%= inspect %>'
    
    def initialize(assigns = {})
      @assigns = assigns
      @sub_templates = []
    end
    
    def method_missing(method, *args)
      @assigns.has_key?(method) ? erb(@assigns[method].to_s) : (parent ? parent.send(method, *args) : super)
    end
    
    def render(path, assigns = {})
      if klass = self.class.resolve(path)
        template = klass.new(assigns)
        template.parent = self; self.sub_templates << template # duplication here?
        template.to_s
      else
        raise "Cannot resolve '#{path}'"
      end
    end
    
    def render_sub_templates
      sub_templates.collect { |template| template.to_s }.join
    end
    
    def to_s
      erb(self.class.template)
    end
    
  protected
  
    def erb(template)
      ERB.new(template, nil, '<>').result(binding)
    end
    
  end
  
  class DSL < Template
        
    self.template = '<%= render_sub_templates %>'
        
    class << self
      
      def construct(&renders)
        @scope = [self.new]
        instance_eval(&renders)
        @scope.first.to_s
      end
      
      def render(path, assigns = {}, &renders)
        template = Template.resolve(path).new(assigns)
        template.parent = @scope.last; @scope.last.sub_templates << template # duplication here?
        if renders
          @scope << template
          instance_eval(&renders)
          @scope.pop
        end
      end
      
    end
    
  end  
    
end