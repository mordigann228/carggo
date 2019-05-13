require "carggo/version"
require "thor"
require 'net/http'
require 'json'

module Carggo
  class Error < StandardError; end

  class CLI < Thor
    desc "find", "generally useles, since Cargo provides this functionality"
    def find(args)
      begin
        escape_uri = URI.escape("https://crates.io/api/v1/crates//#{args}")
        uri = URI.parse(escape_uri)
        res = JSON.parse(Net::HTTP.get(uri))
        printable_response = "#{res["crate"]["name"]} = #{res["crate"]["max_version"]}"
        puts printable_response
        return res
      rescue
        puts "Crate not found"
      end
    end

    desc "add", "adds a crate(crates) to your Cargo.toml dependencies"
    def add(*args)
      if File.exists?("Cargo.toml")
        args.each do |lib|
          crate = self.find(lib)
          cargo = File.open("Cargo.toml", "a") do |out|
            File.foreach("Cargo.toml") do |line|
              if line =~ /dependencies/
                out.puts "[dependencies]\n#{crate["crate"]["name"]} = '#{crate["crate"]["max_version"]}'\n"
              end
            end
          end
        end
      else
        puts "Not a Cargo project directory."
      end
    end

    # desc "remove", "removes the specified dependency"
    # def remove(*args)
    #   p args
    # end
  end
end
