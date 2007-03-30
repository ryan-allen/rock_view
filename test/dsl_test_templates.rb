CView::Template.create 'site/layout' do
  def reformat_heading
    domain.upcase
  end
  assigns :domain
  template "<html><%= render 'heading', :heading => domain.upcase %><%= render_sub_templates %></html>"
end

CView::Template.create 'site/heading' do
  assigns :heading
  template '<h1><%= heading %></html>'
end

CView::Template.create 'site/sidebar' do
  template '<div id="sidebar"><%= render_sub_templates %></div>'
end

CView::Template.create 'site/page' do
  template '<div id="content">Welcome to <%= domain %>!</div><% render \'sidebar\' do %>I AM SIDEBAR!<% end %>'
end

CView::Template.create 'site/footer' do
  assigns :contact
  template '<div id="footer"><%= contact %></div>'
end