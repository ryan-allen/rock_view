require 'cview'

module Rock
  module View
    
    class MissingAssignException < Exception; end
    class UnexpectedAssignException < Exception; end
    
    class << self
      
      def specify(*args, &block)
        CView::Template.create(*args, &block)
      end
      
      def construct(*args, &block)
        CView::DSL.construct(*args, &block)
      end
      
      def resolve(*args)
        CView::Template.resolve(*args)
      end
      
      def render_scope=(val) # deprecate this?
        CView::Template.render_scope = val
      end
      
      def reset!
        CView::Template.reset!
      end
      
      def load(*args)
        CView::Loader.load(*args)
      end
      
    end
  end
end