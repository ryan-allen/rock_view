$: << "#{File.dirname(__FILE__)}/.."
require 'test/unit'
require 'rock_view'

# dsl implements the render dsl that we use that almost exactly mimicks
# usage with the actual class instanciation stuff, so only a small amount
# of test is required cuz template implements all of this?
class DSLTest < Test::Unit::TestCase
  
  def setup
    Rock::View.specify 'layout' do
      def reformat_heading
        domain.upcase
      end
      assigns :domain
      template "<html><%= render 'heading', :heading => domain.upcase %><%= render_sub_templates %></html>"
    end

    Rock::View.specify 'heading' do
      assigns :heading
      template '<h1><%= heading %></html>'
    end

    Rock::View.specify 'sidebar' do
      template '<div id="sidebar"><%= render_sub_templates %></div>'
    end

    Rock::View.specify 'page' do
      template '<div id="content">Welcome to <%= domain %>!</div><% render \'sidebar\' do %>I AM SIDEBAR!<% end %>'
    end

    Rock::View.specify 'footer' do
      assigns :contact
      template '<div id="footer"><%= contact %></div>'
    end
  end
  
  def teardown
    Rock::View.reset!
  end
  
  def test_dsl
    result = Rock::View.construct do
      render 'layout' do
        render 'page', :domain => 'yeahnah.org'
        render 'footer', :contact => "<%= 'RYan@yeahnah.ORG'.downcase %>"
      end
    end
    assert_equal "<html><h1>YEAHNAH.ORG</html><div id=\"content\">Welcome to yeahnah.org!</div><div id=\"sidebar\">I AM SIDEBAR!</div><div id=\"footer\"><%= 'RYan@yeahnah.ORG'.downcase %></div></html>", result
  end
  
end
