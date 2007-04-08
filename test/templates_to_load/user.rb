assign :user

module self::GdaySayer
  def say_gday!
    'gday!'
  end
end

template <<-HTML
User is <%= user %>!
HTML