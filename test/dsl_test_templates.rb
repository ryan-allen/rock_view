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
