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
    CView::Loader.load("#{File.dirname(__FILE__)}/templates_to_load")
  end
  
  def teardown
    CView.reset!
  end
  
  def test_generates_classes
    assert_equal Item, CView::Template.resolve('item')
    assert_equal NoMethod, CView::Template.resolve('no_methods')
    assert_equal User, CView::Template.resolve('user')
  end
  
  def test_includes_methods_from_rb
    item_preview = CView::Template.resolve('item/preview').new(:preview => nil)
    assert_nil item_preview.preview
    assert !item_preview.has_preview?, 'has_preview? should return false for nil preview'
  end
  
  def test_sets_template_from_rhtml
    user = CView::Template.resolve('user').new(:user => 'Collis')
    assert_equal 'User is Collis!', user.to_s
  end
    
end