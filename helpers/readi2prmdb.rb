
require "gdbm"

if ARGV.length == 0
  puts "Please call #{__FILE__} [GDBM DATABASE]"
  puts "Example: #{__FILE__} i2prm.gdbm"
  exit
elsif ! File.exist? ARGV[0]
  puts "\"#{ARGV[0]}\" not found."
  exit
end

db = GDBM.new ARGV[0], 0555, GDBM::READER

puts "Found entries: #{db.keys.join ", "}\n\n"
puts "I2P Keypair:\n#{db["i2p-keys"]}\n\n"
puts "Encryption private key:\n#{db["keypair-privkey"].chars.map { |c| c == "|" ? "\n" : c }.join}\n"
puts "Encryption public key:\n#{db["keypair-pubkey"].chars.map { |c| c == "|" ? "\n" : c }.join}"

db.close