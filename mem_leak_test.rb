#
# We used this script to debug against and fix memory leaks.
#
require 'rock_view'

Rock::View.specify 'template' do
  assigns :a, :b, :c
  template "It's <%= a %>, <%= b %>, <%= c %>."
end

$n = 1_000_000

$n.times do
  Rock::View.resolve('template').new(:a => 1, :b => 2, :c => 3).to_s
end