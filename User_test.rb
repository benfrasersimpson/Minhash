require 'bundler/setup'
gem "minitest"
require 'minitest/autorun'
require './User.rb'

class TestUser < Minitest::Test
    def setup
        @users =[
            User.new(1,0,3),
            User.new(2,2),
            User.new(3,1,3,4),
            User.new(4,0,2,3),
        ]
        @h1 = lambda {|x| (x + 1) % 5}  
        @h2 = lambda {|x| (3 * x + 1) % 5 }
    end

    def test_hash_algorithm
        assert_equal 1, @h1.call(0)
        assert_equal 1, @h2.call(0)
        assert_equal 4, @h1.call(3)
        assert_equal 0, @h2.call(3)
    end

    def test_signatures
        assert_equal [1,0], @users[0].signature(@h1, @h2)
        assert_equal [3,2], @users[1].signature(@h1, @h2)
        assert_equal [0,0], @users[2].signature(@h1, @h2)
        assert_equal [1,0], @users[3].signature(@h1, @h2)
    end
end
