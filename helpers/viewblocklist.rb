
require "gdbm"

db = GDBM.new ARGV[0]

if db.has_key? "blocklist"
  bl = db["blocklist"].to_s.split "~~~"
  if bl.length == 0
    puts "The blocklist contains no entries."
  else
    i = 1
    bl.each { |b64|
      puts "Entry #{i} - #{b64} \n"
      i += 1
    }
  end
else
  puts "There is no block list in the file."
end

db.close