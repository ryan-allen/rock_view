$: << "#{File.dirname(__FILE__)}/.."
require 'test/unit'
require 'cview'

module Site
  class Layout < CView::Template
    assigns :domain
    template "<html><%= render 'site/heading', :heading => domain.upcase %><%= render_sub_templates %></html>"
  end
  class Heading < CView::Template
    assigns :heading
    template '<h1><%= heading %></html>'
  end
  class Sidebar < CView::Template
    template '<div id="sidebar"><%= render_sub_templates %></div>'
  end
  class Page < CView::Template
    template '<div id="content">Welcome to <%= domain %>!</div><% render \'site/sidebar\' do %>I AM SIDEBAR!<% end %>'
  end
  class Footer < CView::Template
    assigns :contact
    template '<div id="footer"><%= contact %></div>'
  end
end

# dsl implements the render dsl that we use that almost exactly mimicks
# usage with the actual class instanciation stuff, so only a small amount
# of test is required cuz template implements all of this?
class DSLTest < Test::Unit::TestCase
  def test_dsl
    result = CView.construct do
      render 'site/layout', :domain => 'yeahnah.org' do
        render 'site/page'
        render 'site/footer', :contact => "<%= 'RYan@yeahnah.ORG'.downcase %>"
      end
    end
    assert_equal "<html><h1>YEAHNAH.ORG</html><div id=\"content\">Welcome to yeahnah.org!</div><div id=\"sidebar\">I AM SIDEBAR!</div><div id=\"footer\"><%= 'RYan@yeahnah.ORG'.downcase %></div></html>", result
  end
end
