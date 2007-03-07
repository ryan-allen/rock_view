$: << "#{File.dirname(__FILE__)}/.."
require 'test/unit'
require 'cview'

class Greeter < CView::Template
  self.template = 'Hello <%= name %>.'
end

class BetterGreeter < Greeter
end

module Sub
  class Page < CView::Template
    self.template = '<h1><%= title %></h1><%= render_sub_templates %>'
    class Part < CView::Template
      self.template = '<div><%= description %></div>'
    end
  end
end

# composition is fully qualified... not sure how to use this in the future...
# we could deal with scoping by traversing subclasses in the future, i think...
class Container < CView::Template
  self.template = "<container><%= render 'container/bit', :name => 1 %><%= render 'container/bit', :name => 2 %></container>"
  class Bit < CView::Template
    self.template = '<bit><%= name %> in <%= container %></bit>'
  end
end
class BitUser < CView::Template
  self.template = "<bit_user><%= render 'container/bit', :name => 1 %><%= render 'container/bit', :name => 2 %></bit_user>"
end

class RudeGreeter < CView::Template
  self.template = 'Piss off <%= name %>!'
end

class Node < CView::Template
end
  
# template is the actual erb template, it can render templates inside of it
# with it's special context and render thingy or something, assigns are shared
# and trickel up but this is handled by the proxychain that is behind method_missing.
# templates also provide an interface for resolving paths and rendering themselves.
# they render by providing references to their parent 'context' and any templates in
# their 'sub_context', assigns tehrefore can be mauled until we call the big old 'to_s'...
class TemplateTest < Test::Unit::TestCase
  def test_can_get_raw_erb_from_template
    assert_equal 'Hello <%= name %>.', Greeter.template
    assert_equal 'Piss off <%= name %>!', RudeGreeter.template
  end
  
  def test_template_is_inherited_by_subclasses
    assert_equal 'Hello <%= name %>.', BetterGreeter.template
  end
  
  def test_assigns_are_acessable_as_methods
    template = CView::Template.new(:one => 1, :two => 2, :a_nil => nil)
    assert_equal '1', template.one
    assert_equal '2', template.two
    assert_equal nil, template.a_nil
  end
  
  def test_to_s_evaluates_erb_template
    assert_equal 'Hello George.', Greeter.new(:name => 'George').to_s
  end
  
  def test_resolve_with_string_returns_template_class
    assert_equal Greeter, CView::Template.resolve('greeter')
  end

  def test_resolve_with_string_returns_template_class_inside_modules
    assert_equal Sub::Page, CView::Template.resolve('sub/page')
  end
  
  def test_resolve_returns_nil_on_missing_template
    assert_nil CView::Template.resolve('bogus/template')
  end
  
  def test_can_have_parent
    page = Sub::Page.new
    part = Sub::Page::Part.new
    assert_nil part.parent
    part.parent = page
    assert_equal page, part.parent
  end
  
  def test_can_have_sub_templates
    page = Sub::Page.new
    part = Sub::Page::Part.new
    assert_equal [], page.sub_templates
    page.sub_templates << part
    assert_equal [part], page.sub_templates
  end
  
  def test_render_sub_templates_renders_sub_templates_in_erb
    page = Sub::Page.new(:title => 'Page')
    page.sub_templates << Sub::Page::Part.new(:description => 'Part 1')
    page.sub_templates << Sub::Page::Part.new(:description => 'Part 2')
    assert_equal '<h1>Page</h1><div>Part 1</div><div>Part 2</div>', page.to_s
  end
  
  def test_can_compose_with_other_templates_using_render_method_in_erb
    composite = Container.new :container => 'container'
    assert_equal '<container><bit>1 in container</bit><bit>2 in container</bit></container>', composite.to_s
  end
  
  def test_can_cross_compose_with_other_templates_using_render_method_in_erb
    composite = BitUser.new :container => 'bit_user'
    assert_equal '<bit_user><bit>1 in bit_user</bit><bit>2 in bit_user</bit></bit_user>', composite.to_s
  end
    
  def test_method_missing_ie_assigns_or_anything_trickle_up_parents_until_handled
    parent = Node.new :root => 'Parent'
    sub1, sub2 = Node.new(:position => '1st'), Node.new(:position => '2nd')
    parent.sub_templates << sub1 << sub2
    sub1.parent, sub2.parent = parent, parent
    assert_equal '1st', sub1.position
    assert_equal '2nd', sub2.position
    assert_equal 'Parent', sub1.root
    assert_equal 'Parent', sub2.root
  end
  
  def test_method_missing_raises_exception_when_nothing_can_handle_it
    assert_raises(NoMethodError) { Node.new.something_is_wrong! }
  end
  
  def test_template_can_be_overriden_per_instance
    greeter = Greeter.new
    assert_equal 'Hello <%= name %>.', greeter.template
    greeter.template = 'Hi <%= name %>.'
    assert_equal 'Hi <%= name %>.', greeter.template
  end
  
end

