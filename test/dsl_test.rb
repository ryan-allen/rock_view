require 'rubygems'
require 'mocha'
require 'stubba'
require 'test/unit'

require '../cview'

module Site
  class Layout < CView::Template
    self.template = '<html><%= render_sub_templates %></html>'
  end
  class Heading < CView::Template
    self.template = '<h1><%= heading %></html>'
  end
  class Page < CView::Template
    self.template = '<div id="content">Welcome to <%= domain %>!</div>'
  end
  class Footer < CView::Template
    self.template = '<div id="footer"><%= contact %></div>'
  end
end

# dsl implements the render dsl that we use that almost exactly mimicks
# usage with the actual class instanciation stuff, so only a small amount
# of test is required cuz template implements all of this?
class DSLTest < Test::Unit::TestCase
  def test_dsl
    result = CView.construct do
      render 'site/layout', :domain => 'yeahnah.org' do
        render 'site/heading', :heading => '<%= domain.upcase %>'
        render 'site/page'
        render 'site/footer', :contact => 'ryan@yeahnah.org'
      end
    end
    assert_equal "<html><h1>YEAHNAH.ORG</html><div id=\"content\">Welcome to yeahnah.org!</div><div id=\"footer\">ryan@yeahnah.org</div></html>", result
  end
end