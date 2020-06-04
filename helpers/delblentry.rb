
require "gdbm"

db = GDBM.new ARGV[0]

if not db.has_key? "blocklist"
  puts "The file does not contain a block list - so one is created."
end

bl = db["blocklist"].to_s.split "~~~"
bl.delete_at ARGV[1].to_i - 1
db["blocklist"] = bl.join "~~~"

db.close
