module RecommendationEngine

    module Minhash
        attr_accessor :bandings

        def signature(hashers)
            signature = Array.new(hashers.size){ Float::INFINITY }
            hashers.each_with_index do |hasher, index|
                @products.sort.each do |product|
                    hash = hasher.call(product)
                    signature[index]= hash if hash < signature[index]
                end
            end
            return signature
        end

        def generate_bandings(banding_hasher, *signature_hashers)
            @bandings = Array.new
            signature(signature_hashers).each_slice(2) do |slice|
                @bandings << banding_hasher.call(*slice)
            end
            return @bandings
        end
    end

    class User
        include Minhash
        attr_accessor :id, :products
        def initialize(id, *products)
            @id = id
            @products = products
            @recommendations = Array.new
        end
        
        def <<(product_id)
            @products << product_id
            return self
        end

        def to_s
            "User ID: #{id} Purchases: #{@products.join(',')}"
        end
    end
   
    class RecommendationEngine
        def initialize(users, banding_algorithm, *signature_algorithms)
            @users = users
            @bandings = Hash.new {|hash, key| hash[key] = Array.new}
            @banding_algorithm = banding_algorithm 
            @signature_algorithms = signature_algorithms
        end

        def generate_bandings
            @users.values.each do |user|
                user_bandings = user.generate_bandings(@banding_algorithm, *@signature_algorithms)
                user_bandings.each {|banding| @bandings[banding] << user.id }
            end

            @bandings.each do |banding, users|
                users.each do |user|
                    @users[user].bandings << banding
                end
            end
        end
  
        def get_recommendation(user_id)
            recommendations = Array.new
            return recommendations unless @users.has_key?(user_id)
            @users[user_id].bandings.each do |banding|
                (@bandings[banding] - [user_id]).each do |other_user|
                    recommendations += (@users[other_user].products - @users[user_id].products)
                end
            end
            return recommendations.uniq
        end

    end
end

