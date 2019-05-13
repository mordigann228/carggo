require "carggo/version"
require "thor"
require 'net/http'
require 'json'
require 'fileutils'

module Carggo
  class Error < StandardError; end

  class CLI < Thor
    desc "find", "generally useles, since Cargo provides this functionality"
    def find(args)
      begin
        escape_uri = URI.escape("https://crates.io/api/v1/crates//#{args}")
        uri = URI.parse(escape_uri)
        res = JSON.parse(Net::HTTP.get(uri))
        name = res["crate"]["name"]
        version = res["crate"]["max_version"]
        printable_response = "#{name} = '#{version}'"
        puts printable_response
        return {name: name, version: version, err: nil}
      rescue
        return {err: true}
      end
    end

    desc "add", "adds a crate(crates) to your Cargo.toml dependencies"
    def add(*args)
      if File.exists?("Cargo.toml")
        args.each do |lib|
          crate = self.find(lib)
          if crate[:err].nil?
            name = crate[:name]
            version = crate[:version]
            File.open("Cargo.toml", "r+") do |out|
              File.foreach("Cargo.toml") do |line|
                if line =~ /#{name}/
                  next
                end
                out << line
                if line =~ /ependen/
                  out << "\n#{name} = '#{version}'"
                end
              end
            end
          else
            puts "Cannot locate #{lib} or having network issues."
          end
        end
      else
        puts "Not a Cargo project directory."
      end
    end

    desc "remove", "removes the specified dependency"
    def remove(*args)
      if File.exists?("Cargo.toml")
        args.each do |lib|
          open("Cargo.toml", 'r') do |out|
            open("Cargo.toml.tmp", 'w') do |out2|
              out.each_line do |line|
                out2.write(line) unless line.start_with? lib
              end
            end
          end
        end
        FileUtils.mv 'Cargo.toml.tmp', 'Cargo.toml'
      else
        puts "Not a Cargo project directory."
      end
    end
  end
end
