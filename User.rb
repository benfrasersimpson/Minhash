#!/usr/bin/env ruby

require 'optparse'
require 'pp'

module RecommendationEngine
    class Application

        def parse_args(argv)
            file = String.new

            opt_parser = OptionParser.new do |opts|
                opts.banner = "Usage: recommendation_engine.rb [options]"

                opts.on("-fFILE", "--file FILE", "File to read user data from") do |f|
                    if File.exists?(f)
                        file = f
                    else
                        puts opts
                        raise "No such file: #{f}"
                        exit
                    end
                end

                opts.on("-h", "--help", "Print this help message") do
                    puts opts
                    exit
                end
            end

            opt_parser.parse!(argv)

            return file
        end

        def initialize(argv)
            file_to_read = parse_args(argv)
            @users = Hash.new {|hash, key| hash[key] = User.new(key)}
            File.open(file_to_read).each_with_index do |line,index|
                next if index == 0
                user_id, product = line.split(';')
                @users[user_id.to_i] << product.to_i
            end
        end

        def run

            r = RecommendationEngine.new(@users)
            r.run

        end
    end
    class User
        attr_accessor :id, :products, :bandings
        def initialize(id, *products)
            @id = id
            @products = products
            @bandings = Array.new
        end
        
        def <<(product_id)
            @products << product_id
            return self
        end

        def to_s
            "User ID: #{id} Purchases: #{@products.join(',')}"
        end
    
        def signature(hashers)
            signature = Array.new(hashers.size){ Float::INFINITY }
            hashers.each_with_index do |hasher, index|
                products.sort.each do |product|
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
    
    class RecommendationEngine
        def initialize(users)
            @users = users
            @bandings = Hash.new {|hash, key| hash[key] = Array.new}
        end

        def generate_bandings
            @users.values.each do |user|
                h1 = lambda {|x| (x + 1) % 103}
                h2 = lambda {|x| (3 * x + 1) % 103 }
                h3 = lambda {|x| (5 * x) + 3 % 103}
                h4 = lambda {|x| (7 * x) - 1 % 103}
                banding_hash = lambda {|x,y=0| ((2 ** x) + 3 ** y) % 103}
                 
                user_bandings = user.generate_bandings(banding_hash, h1, h2, h3, h4)
                user_bandings.each {|banding| @bandings[banding] << user.id }
                raise "No products!" unless user.products.size > 0
            end


            @bandings.each do |banding, users|
                users.each do |user|
                    @users[user].bandings << banding
                end
            end
        end
  
        def get_recommendation(user_id)
            user = @users[user_id]
            recommendations = Array.new
            return recommendations unless @users[user_id]
            raise "No products!" unless @users[user_id].products.size > 0
            @users[user_id].bandings.each do |banding|
                (@bandings[banding] - [user_id]).each do |other_user|
                    recommendations += (@users[other_user].products - @users[user_id].products)
                end
            end
            return recommendations.uniq
        end

        def run
            puts "running"
            generate_bandings
            @users.values.each do |user|
                puts "User ID #{user.id}: #{get_recommendation(user.id)}"
            end
        end
    end
end

app = RecommendationEngine::Application.new(ARGV)
app.run
