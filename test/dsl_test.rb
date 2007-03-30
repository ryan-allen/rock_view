$: << "#{File.dirname(__FILE__)}/.."
require 'test/unit'
require 'cview'

# dsl implements the render dsl that we use that almost exactly mimicks
# usage with the actual class instanciation stuff, so only a small amount
# of test is required cuz template implements all of this?
class DSLTest < Test::Unit::TestCase
  
  def setup
    CView.reset!
    load "#{File.dirname(__FILE__)}/dsl_test_templates.rb"
  end
  
  def teardown
    CView.reset!
  end
  
  def test_dsl
    CView.render_scope = 'site'
    result = CView.construct do
      render 'layout' do
        render 'page', :domain => 'yeahnah.org'
        render 'footer', :contact => "<%= 'RYan@yeahnah.ORG'.downcase %>"
      end
    end
    assert_equal "<html><h1>YEAHNAH.ORG</html><div id=\"content\">Welcome to yeahnah.org!</div><div id=\"sidebar\">I AM SIDEBAR!</div><div id=\"footer\"><%= 'RYan@yeahnah.ORG'.downcase %></div></html>", result
  end
  
end
