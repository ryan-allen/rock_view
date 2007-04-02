$: << "#{File.dirname(__FILE__)}/.."
require 'test/unit'
require 'rock_view'

class SpecTest < Test::Unit::TestCase
  
  def setup
    @spec = Rock::View::Spec.new
  end
  
  def test_has_assigns
    expected_assigns = [:one, :two]
    @spec.assigns *expected_assigns
    assert_equal expected_assigns, @spec.assigns
  end
  
  def test_has_defaults
    @spec.assign :one, :default => 1
    assert_equal [:one], @spec.assigns
    assert_equal 1, @spec.defaults[:one]
  end
  
  def test_has_expectations
    @spec.assign :one, :expects => [1, 'one']
    assert_equal [:one], @spec.assigns
    assert_equal [1, 'one'], @spec.expectations[:one]
  end
  
  def test_has_template
    @spec.template 'one, two, three'
    assert_equal 'one, two, three', @spec.template
  end
  
end
  
