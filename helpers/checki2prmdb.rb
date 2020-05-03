
require "gdbm"
require "openssl"
require "socket"

if ARGV.length == 0
  puts "Please call #{__FILE__} [GDBM DATABASE]"
  puts "Example: #{__FILE__} i2prm.gdbm"
  exit
elsif ! File.exist? ARGV[0]
  puts "\"#{ARGV[0]}\" not found."
  exit
end

db = GDBM.new ARGV[0], 0555, GDBM::READER

begin
  OpenSSL::PKey::RSA.new db["keypair-privkey"].chars.map { |c| c == "|" ? "\n" : c }.join
rescue OpenSSL::PKey::RSAError => rsaerror
  puts "Invalid private key: #{rsaerror.message}"
else
  puts "Valid private key."
end

begin
  OpenSSL::PKey::RSA.new db["keypair-pubkey"].chars.map { |c| c == "|" ? "\n" : c }.join
rescue OpenSSL::PKey::RSAError => rsaerror
  puts "Invalid public key: #{rsaerror.message}"
else
  puts "Valid public key."
end

cli = TCPSocket.new "127.0.0.1", 2827
cli.gets; cli.gets

cli.puts "verify #{db["i2p-keys"]}"
ans = cli.gets.chomp
if ans[0...2] == "OK"
  puts "Valid i2p keys."
else
  puts "Invalid i2p keys: #{ans[6..-1]}"
end
cli.puts "quit"; cli.gets
cli.close
