
require "openssl"
require "socket"
require "gdbm"

def randomname len=5
  symbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
  res = ""
  rnd = Random.new
  for i in 0...len
    res += symbols[rnd.rand(0...symbols.length)]
  end
  return res
end

def createdatabase cli
  fn = "i2prm.gdbm-#{randomname}"
  fn = "i2prm.gdbm-#{randomname}" while File.exist? fn
  db = GDBM.new fn

  puts "Create new OpenSSL RSA keys"
  privkey = OpenSSL::PKey::RSA.new 4096
  puts "Save private key to database"
  db["keypair-privkey"] = privkey.to_s.chars.map { |c| c == "\n" ? "|" : c }.join
  puts "Save public key to database"
  db["keypair-pubkey"] = privkey.public_key.to_s.chars.map { |c| c == "\n" ? "|" : c }.join

  puts "Create new I2P keys"
  cli.puts "newkeys"
  cli.gets
  cli.puts "getkeys"
  puts "Save I2P keys to database"
  db["i2p-keys"] = cli.gets.chomp[3..-1]

  puts "Close database"
  db.close
end

if ARGV.length == 0
  puts "Please call #{__FILE__} [NUMBER OF DATABASES]"
  puts "Example: #{__FILE__} 2"
  exit
end

z = ARGV[0].to_i
exit if z == 0

puts "Open connection to BOB API"
cli = TCPSocket.new "127.0.0.1", 2827
puts "BOB API: #{cli.gets}"
puts "BOB API: #{cli.gets}"
cli.puts "setnick onlyforcreatekeys"
puts "BOB API: #{cli.gets}"

for i in 1..z
  puts "---- #{i}/#{z} ----"
  createdatabase cli
  sleep 0.5
end

cli.puts "quit"
puts "\nClose connection to BOB API"
puts "BOB API: #{cli.gets}"
cli.close