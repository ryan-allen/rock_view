CView::Template.create 'greeter' do
  assign :name
  template 'Hello <%= name %>.'
end

# CView::Template.define 'greeter' do
#   assign :name
#   template 'Hello <%= name %>'
# end

# class BetterGreeter < Greeter
# end

CView::Template.create 'sub/page' do
  assign :title
  template '<h1><%= title %></h1><%= render_sub_templates %>'
end

CView::Template.create 'sub/page/part' do
  assign :description
  template '<div><%= description %></div>'
end

# composition is fully qualified... not sure how to use this in the future...
# we could deal with scoping by traversing subclasses in the future, i think...
CView::Template.create 'container' do
  template "<container><%= render 'container/bit', :name => 1, :container => 'container' %><%= render 'container/bit', :name => 2, :container => 'container' %></container>"
end
CView::Template.create 'container/bit' do
  assigns :name, :container
  template '<bit><%= name %> in <%= container %></bit>'
end

CView::Template.create 'bit_user' do
  assign :name
  template "<bit_user><%= render 'container/bit', :name => 1, :container => name %><%= render 'container/bit', :name => 2, :container => name %></bit_user>"
end

CView::Template.create 'rude_greeter' do
  assign :name
  template 'Piss off <%= name %>!'
end

CView::Template.create 'person' do
  assigns :name, :age
  assign :colour, :default => 'Red'
  assign :gender, :expects => ['M', 'F']
end

CView::Template.create 'root_node' do
  assign :root
end
CView::Template.create 'node' do
  assign :position
end

CView::Template.create 'assign_default_is_nil' do
  assign :is_nil, :default => nil
end