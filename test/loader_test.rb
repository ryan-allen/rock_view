$: << "#{File.dirname(__FILE__)}/.."
require 'test/unit'
require 'cview'

# loader loads and construct views from a path, i.e. if you go CView::Loader.load('./views')
# it will for example, take item.rb and item.rhtml and make a class called Item, running item.rb
# in context of the class and setting the template class var to string content of item.rhtml
# it also looks in subdirs and maps correctly, i.e. item/files/preview.rb will create Item::Files::Preview
# which is accessible with CView::Template.resolve('item/files/preview')
class LoaderTest < Test::Unit::TestCase
  
  def setup
    CView.reset!
    CView::Loader.load("#{File.dirname(__FILE__)}/templates_to_load")
  end
  
  def teardown
    CView.reset!
  end
  
  def test_generates_classes
    assert_not_nil CView::Template.resolve('item')
    assert_not_nil CView::Template.resolve('no_method')
    assert_not_nil CView::Template.resolve('user')
    # assert_equal Item, CView::Template.resolve('item')
    # assert_equal NoMethod, CView::Template.resolve('no_methods')
    # assert_equal User, CView::Template.resolve('user')
  end
  
  def test_includes_methods_from_rb
    item_preview = CView::Template.resolve('item/preview').new(:preview => nil)
    assert_nil item_preview.preview
    assert !item_preview.has_preview?, 'has_preview? should return false for nil preview'
  end
  
  def test_sets_template_from_rhtml
    user = CView::Template.resolve('user').new(:user => 'Collis')
    assert_equal "User is Collis!\n", user.to_s
  end
  
  def test_can_load_into_module_scope
    CView.reset!
    Object.class_eval('module View; end')
    CView::Loader.load("#{File.dirname(__FILE__)}/templates_to_load", 'view')
    assert_not_nil CView::Template.resolve('view/item')
    assert_not_nil CView::Template.resolve('view/no_method')
    assert_not_nil CView::Template.resolve('view/user')
    # assert View::Item
    # assert View::NoMethod
    # assert View::User
  end
  
  def test_can_have_modules_inside_classes
    assert_equal 'hi', CView::Template.resolve('item')::InnerModule.hi
  end
    
end