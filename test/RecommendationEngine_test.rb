require 'minitest/autorun'
require_relative '../lib/RecommendationEngine.rb'

class TestMinhash < Minitest::Test
    def setup
        @users =[
            RecommendationEngine::User.new(1,0,3),
            RecommendationEngine::User.new(2,2),
            RecommendationEngine::User.new(3,1,3,4),
            RecommendationEngine::User.new(4,0,2,3),
        ]
        @h1 = lambda {|x| (x + 1) % 5}  
        @h2 = lambda {|x| (3 * x + 1) % 5 }
        @banding_algorithm = lambda {|x,y=0| ((3 * x) + y) % 5}
    end

    def test_hash_algorithm
        assert_equal 1, @h1.call(0)
        assert_equal 1, @h2.call(0)
        assert_equal 4, @h1.call(3)
        assert_equal 0, @h2.call(3)
    end

    def test_signatures
        assert_equal [1,0], @users[0].signature([@h1, @h2])
        assert_equal [3,2], @users[1].signature([@h1, @h2])
        assert_equal [0,0], @users[2].signature([@h1, @h2])
        assert_equal [1,0], @users[3].signature([@h1, @h2])
    end

    def test_banding
        assert_equal [3], @users[0].generate_bandings(@banding_algorithm, @h1, @h2)
        assert_equal [1], @users[1].generate_bandings(@banding_algorithm, @h1, @h2)
        assert_equal [0], @users[2].generate_bandings(@banding_algorithm, @h1, @h2)
        assert_equal [3], @users[3].generate_bandings(@banding_algorithm, @h1, @h2)
    end
end

class TestRecommendationEngine < Minitest::Test
    def setup
        h1 = lambda {|x| (x + 1) % 5 }
        h2 = lambda {|x| (3 * x + 1) % 5}
        h3 = lambda {|x| (2 * x) + 4 % 5}
        h4 = lambda {|x| (3 * x) - 1 % 5}
        banding_hash = lambda {|x,y=0| ((7 * x) + (11 * y)) % 15}

        @users = {
            1 => RecommendationEngine::User.new(1,0,3),
            2 => RecommendationEngine::User.new(2,2),
            3 => RecommendationEngine::User.new(3,1,3,4),
            4 => RecommendationEngine::User.new(4,0,2,3),
        }
        @r = RecommendationEngine::RecommendationEngine.new(@users, banding_hash, h1, h2, h3, h4)
        @r.generate_bandings
    end

    def test_can_generate_recommendations
        refute_empty(@r.get_recommendation(1))
    end

    def test_recommendation_for_similar_users
        assert_includes(@r.get_recommendation(1), 2)
    end

    def test_no_recommendation_for_dissimilar_users
        assert_empty(@r.get_recommendation(2))
    end

end

class TestOnDawandaData < MiniTest::Test

    def setup
        h1 = lambda {|x| (x + 1) % 103}
        h2 = lambda {|x| (3 * x + 1) % 103 }
        h3 = lambda {|x| (5 * x) + 3 % 103}
        h4 = lambda {|x| (7 * x) - 1 % 103}
        banding_hash = lambda {|x,y=0| ((13 * x) + (17 * y)) % 103}

        @users = {
            1 => RecommendationEngine::User.new(1, 12, 99, 32),
            2 => RecommendationEngine::User.new(2, 32, 77, 54, 66),
            3 => RecommendationEngine::User.new(3, 99, 42, 12, 32),
            4 => RecommendationEngine::User.new(4, 77, 66, 47),
            5 => RecommendationEngine::User.new(5, 65)
        }
        @r = RecommendationEngine::RecommendationEngine.new(@users, banding_hash, h1, h2, h3, h4)
        @r.generate_bandings
    end

    #Users 1 and 3 similar, apart from product 42
    def test_recommendation_for_similar_users
        assert_includes(@r.get_recommendation(1), 42)
    end

    #No other user has bought product 65 apart from user 5
    def test_recommendation_for_dissimilar_users
        assert_empty(@r.get_recommendation(5))
    end
end
