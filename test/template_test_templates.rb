class Greeter < CView::Template
  assign :name
  template 'Hello <%= name %>.'
end

class BetterGreeter < Greeter
end

module Sub
  class Page < CView::Template
    assign :title
    template '<h1><%= title %></h1><%= render_sub_templates %>'
    class Part < CView::Template
      assign :description
      template '<div><%= description %></div>'
    end
  end
end

# composition is fully qualified... not sure how to use this in the future...
# we could deal with scoping by traversing subclasses in the future, i think...
class Container < CView::Template
  template "<container><%= render 'container/bit', :name => 1, :container => 'container' %><%= render 'container/bit', :name => 2, :container => 'container' %></container>"
  class Bit < CView::Template
    assigns :name, :container
    template '<bit><%= name %> in <%= container %></bit>'
  end
end
class BitUser < CView::Template
  assign :name
  template "<bit_user><%= render 'container/bit', :name => 1, :container => name %><%= render 'container/bit', :name => 2, :container => name %></bit_user>"
end

class RudeGreeter < CView::Template
  assign :name
  template 'Piss off <%= name %>!'
end

class Person < CView::Template
  assigns :name, :age
  assign :colour, :default => 'Red'
  assign :gender, :expects => ['M', 'F']
end

class RootNode < CView::Template
  assign :root
end
class Node < CView::Template
  assign :position
end

class AssignDefaultIsNil < CView::Template
  assign :is_nil, :default => nil
end