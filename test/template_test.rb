$: << "#{File.dirname(__FILE__)}/.."
require 'test/unit'
require 'rock_view'
  
# template is the actual erb template, it can render templates inside of it
# with it's special context and render thingy or something, assigns are shared
# and trickel up but this is handled by the proxychain that is behind method_missing.
# templates also provide an interface for resolving paths and rendering themselves.
# they render by providing references to their parent 'context' and any templates in
# their 'sub_context', assigns tehrefore can be mauled until we call the big old 'to_s'...
class TemplateTest < Test::Unit::TestCase
  
  def setup
    Rock::View.specify 'greeter' do
      assign :name
      template 'Hello <%= name %>.'
    end

    Rock::View.specify 'sub/page' do
      assign :title
      template '<h1><%= title %></h1><%= render_sub_templates %>'
    end

    Rock::View.specify 'sub/page/part' do
      assign :description
      template '<div><%= description %></div>'
    end

    # composition is fully qualified... not sure how to use this in the future...
    # we could deal with scoping by traversing subclasses in the future, i think...
    Rock::View.specify 'container' do
      template "<container><%= render 'container/bit', :name => 1, :container => 'container' %><%= render 'container/bit', :name => 2, :container => 'container' %></container>"
    end
    Rock::View.specify 'container/bit' do
      assigns :name, :container
      template '<bit><%= name %> in <%= container %></bit>'
    end

    Rock::View.specify 'bit_user' do
      assign :name
      template "<bit_user><%= render 'container/bit', :name => 1, :container => name %><%= render 'container/bit', :name => 2, :container => name %></bit_user>"
    end

    Rock::View.specify 'rude_greeter' do
      assign :name
      template 'Piss off <%= name %>!'
    end

    Rock::View.specify 'person' do
      assigns :name, :age
      assign :colour, :default => 'Red'
      assign :gender, :expects => ['M', 'F']
    end

    Rock::View.specify 'root_node' do
      assign :root
    end
    Rock::View.specify 'node' do
      assign :position
    end

    Rock::View.specify 'assign_default_is_nil' do
      assign :is_nil, :default => nil
      template '<%= inspect %>'
    end
  end
  
  def teardown
    Rock::View.reset!
  end
  
  def test_reset_removes_template_constants
    assert_not_nil Rock::View.resolve('greeter'), 'Greeter should be defined'
    Rock::View.reset!
    assert_nil Rock::View.resolve('greeter'), 'Greeter should NOT be defined'
  end
  
  def test_can_get_raw_erb_from_template
    assert_equal 'Hello <%= name %>.', Rock::View.resolve('greeter').template
    assert_equal 'Piss off <%= name %>!', Rock::View.resolve('rude_greeter').template
  end
    
  def test_assigns_have_accessors_and_are_created_with_hash
    template = Rock::View.resolve('person').new(:name => 'Ryan')
    assert_equal 'Ryan', template.name
    template.name = 'Collis'
    assert_equal 'Collis', template.name
  end
  
  def test_assigns_can_have_default_values
    template = Rock::View.resolve('person').new
    assert_equal 'Red', template.colour
  end
  
  def test_to_s_raises_exception_when_assign_is_nil
    template = Rock::View.resolve('person').new
    assert_raises(Rock::View::MissingAssignException) { template.to_s }
  end
  
  def test_to_s_doesnt_raise_exception_when_assign_is_nil_but_default_is_nil
    assert_nothing_raised { Rock::View.resolve('assign_default_is_nil').new.to_s }
  end
  
  def test_to_s_raises_exception_when_assign_vaule_is_not_in_expected
    template = Rock::View.resolve('person').new(:name => 'Ryan', :age => '24', :gender => '?')
    assert_raises(Rock::View::UnexpectedAssignException) { template.to_s }
  end
    
  def test_to_s_evaluates_erb_template
    assert_equal 'Hello George.', Rock::View.resolve('greeter').new(:name => 'George').to_s
  end
    
  def test_resolve_returns_nil_on_missing_template
    assert_nil Rock::View.resolve('bogus/template')
  end
  
  def test_can_have_parent
    page = Rock::View.resolve('sub/page').new
    part = Rock::View.resolve('sub/page/part').new
    assert_nil part.parent
    part.parent = page
    assert_equal page, part.parent
  end
  
  def test_can_have_sub_templates
    page = Rock::View.resolve('sub/page').new
    part = Rock::View.resolve('sub/page/part').new
    assert_equal [], page.sub_templates
    page.sub_templates << part
    assert_equal [part], page.sub_templates
  end
  
  def test_render_sub_templates_renders_sub_templates_in_erb
    page = Rock::View.resolve('sub/page').new(:title => 'Page')
    page.sub_templates << Rock::View.resolve('sub/page/part').new(:description => 'Part 1')
    page.sub_templates << Rock::View.resolve('sub/page/part').new(:description => 'Part 2')
    assert_equal '<h1>Page</h1><div>Part 1</div><div>Part 2</div>', page.to_s
  end
  
  def test_can_compose_with_other_templates_using_render_method_in_erb
    composite = Rock::View.resolve('container').new
    assert_equal '<container><bit>1 in container</bit><bit>2 in container</bit></container>', composite.to_s
  end
  
  def test_can_cross_compose_with_other_templates_using_render_method_in_erb
    composite = Rock::View.resolve('bit_user').new :name => 'bit_user'
    assert_equal '<bit_user><bit>1 in bit_user</bit><bit>2 in bit_user</bit></bit_user>', composite.to_s
  end
    
  def test_method_missing_ie_assigns_or_anything_trickle_up_parents_until_handled
    parent = Rock::View.resolve('root_node').new :root => 'Parent'
    sub1 = Rock::View.resolve('node').new(:position => '1st')
    sub2 = Rock::View.resolve('node').new(:position => '2nd')
    parent.sub_templates << sub1 << sub2
    sub1.parent, sub2.parent = parent, parent
    assert_equal '1st', sub1.position
    assert_equal '2nd', sub2.position
    assert_equal 'Parent', sub1.root
    assert_equal 'Parent', sub2.root
  end
  
  def test_method_missing_raises_exception_when_nothing_can_handle_it
    assert_raises(NoMethodError) { Rock::View.resolve('node').new.something_is_wrong! }
  end
  
  def test_template_can_be_overriden_per_instance
    greeter = Rock::View.resolve('greeter').new
    assert_equal 'Hello <%= name %>.', greeter.template
    greeter.template = 'Hi <%= name %>.'
    assert_equal 'Hi <%= name %>.', greeter.template
  end
  
end

