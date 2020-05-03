
require "gdbm"
require "openssl"

fn = nil

if ARGV[0].to_i < 512
  puts "The new key strength must be over 512 bytes."
  puts "The current one is #{ARGV[0].to_i}."
  exit
end

if ARGV.length <= 1
  fn = "i2prm.gdbm"
else
  fn = ARGV[1]
end

unless File.exist? fn
  puts "Can not found \"#{fn}\"."
  exit
end

db = GDBM.new fn

puts "Create new OpenSSL RSA keys"
privkey = OpenSSL::PKey::RSA.new ARGV[0].to_i
puts "Save private key to database"
db["keypair-privkey"] = privkey.to_s.chars.map { |c| c == "\n" ? "|" : c }.join

puts "Reorganize database"
db.reorganize
db.close