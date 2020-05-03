
require "gdbm"

def delredkey db, key
  if db.has_key? key
    puts "Found redundant key: #{key}"
    db.delete key
  else
    puts "Do not found redundant key: #{key}"
  end
end

fn = nil

if ARGV.length == 0
  fn = "i2prm.gdbm"
else
  if File.exist? ARGV[0]
    fn = ARGV[0]
  else
    puts "Can not found \"#{ARGV[0]}\"."
    exit
  end
end

db = GDBM.new fn

delredkey db, "keypair-pubkey"

puts "Reorganize database"
db.reorganize
db.close