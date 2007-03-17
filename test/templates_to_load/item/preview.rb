assign :preview

def has_preview?
  not preview.nil?
end

template <<-HTML
<% if has_preview? %>
  <img src="<%= preview.url %>" />
<% else %>
  <img src="default_preview.jpg" />
<% end %>
HTML