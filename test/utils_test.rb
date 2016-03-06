require 'test_helper'

class UtilsTest < MiniTest::Test

  def setup
    @object = Object.new
    @object.extend(ScaleWorkers::Utils)
  end

  def test_say
    assert_equal "Hello", @object.say("Hello")
  end

end
