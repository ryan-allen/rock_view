module self::InnerModule
  def self.hi
    'hi'
  end
end

include Rock::View.resolve('user')::GdaySayer