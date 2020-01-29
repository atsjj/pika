require 'test_helper'

class PikaTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Pika::VERSION
  end
end
