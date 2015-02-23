require 'optparse'
require_relative 'lib/RecommendationEngine.rb'

module RecommendationEngine
    class Application

        def parse_args(argv)
            options = {}

            opt_parser = OptionParser.new do |opts|
                opts.banner = "Usage: recommendation_engine.rb [options]"

                opts.on("-f", "--file FILE", "File to read user data from") do |f|
                    if File.exists?(f)
                        options[:file] = f
                    end
                end

                opts.on("-h", "--help", "Print this help message") do
                    puts opts
                    exit
                end
            end
            opt_parser.parse!(argv)
            mandatory = [:file]
            missing = mandatory.select {|param| options[param].nil?}
            unless missing.empty?
                puts "Missing options: #{missing.join(', ')}"
                puts opt_parser
                exit
            end
            return options
        end

        def initialize(argv)
            options = parse_args(argv)
            @users = Hash.new {|hash, key| hash[key] = User.new(key)}
            File.open(options[:file]).each_with_index do |line,index|
                next if index == 0
                user_id, product = line.split(';')
                @users[user_id.to_i] << product.to_i
            end
        end

        def run
            h1 = lambda {|x| (x + 1) % 103}
            h2 = lambda {|x| (3 * x + 1) % 103 }
            h3 = lambda {|x| (5 * x) + 3 % 103}
            h4 = lambda {|x| (7 * x) - 1 % 103}
            banding_hash = lambda {|x,y=0| ((2 ** x) + 3 ** y) % 103}
            r = RecommendationEngine.new(@users, banding_hash, h1, h2, h3, h4)
            r.generate_bandings

            print "Enter User ID to get recommendations, or EOF (CTRL + D) to exit: "
            while input = STDIN.gets
                recommendations = r.get_recommendation(input.to_i)
                if recommendations.empty?
                    puts "No recommendations"
                else
                    puts "User ID #{input.strip} recommendations: #{recommendations.join(',')}"
                end
                print "Enter a User ID: "
            end
        end
    end
end

app = RecommendationEngine::Application.new(ARGV)
app.run
