$: << "#{File.dirname(__FILE__)}/.."
require 'test/unit'
require 'rock_view'

## THIS COMMENT IS OUT OF DATE!

# loader loads and construct views from a path, i.e. if you go CView::Loader.load('./views')
# it will for example, take item.rb and item.rhtml and make a class called Item, running item.rb
# in context of the class and setting the template class var to string content of item.rhtml
# it also looks in subdirs and maps correctly, i.e. item/files/preview.rb will create Item::Files::Preview
# which is accessible with CView::Template.resolve('item/files/preview')
class LoaderTest < Test::Unit::TestCase
  
  def setup
    Rock::View.load("#{File.dirname(__FILE__)}/templates_to_load")
  end
  
  def teardown
    Rock::View.reset!
  end
  
  def test_generates_classes
    assert_not_nil Rock::View.resolve('item')
    assert_not_nil Rock::View.resolve('no_method')
    assert_not_nil Rock::View.resolve('user')
  end
  
  def test_includes_methods_from_rb
    item_preview = Rock::View.resolve('item/preview').new(:preview => nil)
    assert_nil item_preview.preview
    assert !item_preview.has_preview?, 'has_preview? should return false for nil preview'
  end
  
  def test_sets_template_from_rhtml
    user = Rock::View.resolve('user').new(:user => 'Collis')
    assert_equal "User is Collis!\n", user.to_s
  end
  
  # def test_can_load_into_module_scope
  #   Rock::View.reset!
  #   Rock::View.load("#{File.dirname(__FILE__)}/templates_to_load", 'view')
  #   assert_not_nil Rock::View.resolve('view/item')
  #   assert_not_nil Rock::View.resolve('view/no_method')
  #   assert_not_nil Rock::View.resolve('view/user')
  # end
  
  def test_can_have_modules_inside_classes
    assert_equal 'hi', Rock::View.resolve('item')::InnerModule.hi
  end
  
  def test_loader_can_include_modules_from_another_view
    assert_equal 'gday!', Rock::View.resolve('item').new.say_gday!
  end
    
end