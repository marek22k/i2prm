
=begin
Copyright 2020 Marek Küthe

This program is free software. It comes without any warranty, to
the extent permitted by applicable law. You can redistribute it
and/or modify it under the terms of the Do What The Fuck You Want
To Public License, Version 2, as published by Sam Hocevar. See
http://www.wtfpl.net/ for more details.
=end

require "socket"

# rescue
if ARGV[0] == "rescue"
  sock = TCPSocket.new "127.0.0.1", 2827
  sock.gets
  sock.gets
  
  sock.puts "getnick i2pm"
  puts "BOB API: " + sock.gets.chomp
  sleep 2
  
  sock.puts "stop"
  puts "BOB API: " + sock.gets.chomp
  sleep 2
  
  sock.puts "clear"
  puts "BOB API: " + sock.gets.chomp
  sleep 2
  
  sock.puts "clear"
  puts "BOB API: " + sock.gets.chomp
  sleep 2
  
  sock.puts "quit"
  puts "BOB API: " + sock.gets.chomp
  sock.close
  
  puts "Complete!"
  exit
elsif ARGV[0] == "feedback"
  puts "Thank you for giving me feedback on i2prm. Please note the product is not stable. So errors can occur.
You can give me feedback via email:
mark22k@mail.i2p or mark22k@i2pmail.org"
  exit
elsif ARGV[0] == "fxruby"
  puts "fxruby is the module that I use to create a GUI. If there are any problems, there are hints on GitHub: https://github.com/larskanis/fxruby"
  exit
elsif ARGV[0] == "whyrescue"
  puts "The rescue command is used if i2prm has been closed without disconnecting. If this happens, a new connection cannot be established when restarting. To solve this problem you can run *ruby i2prm.rb rescue*."
  exit
elsif ARGV[0] == "help"
  
  $helptext = 'i2prm is a peer-to-peer messenger that uses the I2P network.
The BOB API is used to communicate with the I2P router.
The messages can be encrypted again in addition to the I2P encryption.
  
Download and install i2prm

    Install the Ruby interpreter. There is a manual on ruby-lang.org
    Install fxruby. First, a few components have to be installed in Ubuntu/Debian:
    sudo apt-get install g++ libxrandr-dev libfox-1.6-dev command.
    There\'s nothing to do with Windows.
    To install the gem you can run gem install fxruby on the command line.
    Next you can download the current version on BitBucket [Mirror].
    If necessary, the i2prm.rb file must be extracted from the ZIP folder.
    The program can then be started from the command line with ruby i2prm.rb.

How do I connect i2prm to the I2P network?

    Enter a nickname in the I2P Row Messenger window if necessary. This is freely selectable.
    Anyone who knows your base64 can also determine your nickname. If you don\'t want to type
    in, you can also leave the randomly generated nickname.
    Then click the "Connect" button and wait. Depending on how well the I2P router is integrated,
    this process can take a little longer. When the process has been successfully completed,
    the status changes to "Connected" and the message "OK tunnel starting" appears below.

How do I connect to someone else?

    In the "I2P Row Messenger" window in the "Contact\'s base64:"
    text box, enter the base64 address of the contact you want to add.
    Next click on Add contact.
    Wait a few seconds. This process can take up to a minute.
        The text "Ready. Receive public: true" should appear on the lower label.
        If the Java error "no route to host" appears, one of the two contacts is not
        integrated enough in the I2P network. It\'s best to try again in a few
        minutes. If it still doesn\'t work, restarting i2prm can sometimes help.
    If the connection process was successful, the nickname of the contact appears
    next in the Contact List in the Messages window.

How do I send a message?

    In the Messages window in the contact list, select the nickname to which you want to send a message.
    Enter the message in the bottom text box of the Messages window.
        To send the message encrypted, enter a symbol (;) in the text box or click on the "Send" button.
        To send the message unencrypted, click on the "U" button.

How do I close a conversation?

    In the Messages window in the contact list, select the nickname of the
    conversation at which you want to close the conversation.
    Then click on the "Close" button at the bottom right.


The message ERROR tunnel settings incomplete appears.
What can I do about it?

    This message often appears when i2prm has ended but the connection continues. To fix this
    error, start the Ruby script with the argument "rescue" ie ruby i2prm.rb rescue.
    This process takes a bit. Finally, the message "Complete!" appear.
    The whole issue should look something like this:
    BOB API: OK Nickname set to i2pm
    BOB API: OK tunnel stopping
    BOB API: OK cleared
    BOB API: ERROR no nickname has been set
    BOB API: OK Bye!
    Complete!

What does the v, i, m and u mean in square brackets in messages?
When an encrypted message is sent, it is automatically signed to
confirm that it actually came from the sender. Unencrypted messages are not signed.

    v(valid) means that the signature is valid.
    i(invalid) means that the signature is invalid.
    u(unencrypted) means that the message is unencrypted and therefore not signed.
    m(me or myself) means that the message comes from yourself and is therefore also valid.

How do I change the key strength?
Note: To change this, you have to change the source code of the program.
The default strength is 4096 bytes.
This key is used to encrypt/decrypt the received messages.

    Open the i2prm.rb file with any editor. However, I recommend using syntax highlighting for an overview.
    Find the line with the following content: $mykeypair = Encryption::Keypair.new 4096
    Replace the number 4096 with the desired key strength.

How do I change the length of the verification string?
Note: To change this, you have to change the source code of the program.
The connection partner is sent a verification string to confirm that it has
transmitted its real base64. The default length is 32 characters.

    Open the i2prm.rb file with any editor. However, I recommend using syntax highlighting for an overview.
    Find the line with the following content: $codelen = 32
    Replace the number 32 with the desired key length.'
  
  require "fox16"
  
  class HelpWindow < Fox::FXMainWindow
    include Fox
    
    def initialize app
      super(app, "Help", :width=>600, :height=>400)
      
      helpText = FXText.new self, :opts => LAYOUT_FILL
      helpText.editable = false
      helpText.text = $helptext
    end
    
    def create
      super
      show(Fox::PLACEMENT_SCREEN)
    end
  end
  app = Fox::FXApp.new
  help = HelpWindow.new app
  app.create
  app.run
  exit
end

require "fox16"
require "gdbm"
require "openssl"

$db = GDBM.new "i2prm.gdbm"
$blocklist = $db["blocklist"].to_s.split "~~~"
at_exit {
  $db["blocklist"] = $blocklist.join "~~~"
  $db.close
}

if $db.has_key? "keypair-privkey"
  $privkey = OpenSSL::PKey::RSA.new $db["keypair-privkey"].chars.map { |c| c == "|" ? "\n" : c }.join
  $pubkey = $privkey.public_key
else
  $privkey = OpenSSL::PKey::RSA.new 4096
  $pubkey = $privkey.public_key
  $db["keypair-privkey"] = $privkey.to_s.chars.map { |c| c == "\n" ? "|" : c }.join
end

$i2cpsettings = Hash.new
$sendpubkey = $pubkey.to_s.chars.map { |c| c == "\n" ? "|" : c }.join
$codelen = 32
$codes = Hash.new
$msgs = Hash.new
$current = ""
$sockss = Hash.new
$b64ss = Hash.new
$digest = OpenSSL::Digest::SHA512.new
$logfile = "i2prm.err.log"
$logio = File.new $logfile, "w"
$sigintcounter = 0
at_exit { $logio.close }

$icon = "\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR\x00\x00\x00@\x00\x00\x00@\b\x06\x00\x00\x00\xAAiq\xDE\x00\x00\x00\x04sBIT\b\b\b\b|\bd\x88\x00\x00\x00\tpHYs\x00\x00\x00\xCE\x00\x00\x00\xCE\x01\x94\xFE\x93\xA0\x00\x00\x00\x19tEXtSoftware\x00www.inkscape.org\x9B\xEE<\x1A\x00\x00\t-IDATx\x9C\xE5\x9B{lS\xD7\x19\xC0\x7F\xD7\xD7v\xE2Gn\x1C\x03I\x9C&\x90`\xCC\xB3\xA5\x11\x90\xB6c\x84\x01*lb\xD5\x06\xAC\x9B\x98\x06eB\xDD\xFAG7\xA4E\xDA:\xB5\xEB\x16\xA9h\xD2V\xAD\xA0\xB1\xAA\b\x06ja\xAA\xD8V\xCA\xB4\x8D?\xB6\x16\xD8\v(\x14\rB\x804\x0E4\x90\xF2\x88\xC9\x03\xE7m\xC7\xF1\xBD\xFB\xE3&!\xF6\xBD&v\xECk\xE8\xFA\x93\"\xC5\xE7|\xE7\xDC\xEF\xFB\xEE9\xE7~\xE7\xBB\xE7\n\x8CAQ\x14'`\xE1\xFF\x9B\x88 \b\xBD#?\x04\x00EQ\x1E\x05\xF6\x03\x8F\xDC/\xAD\xB2L=\xB0A\x10\x84\xF3#\x0E\xA8\a\x1E\xBE\xBF:e\x9D\xF3\x82 <*(\x8A\x92\at\x8F'=\x14\x1D\xA2\xAB\xA7\x8Bh4\x8AKra\xB5X\xB3\xA0c\n\f\x84\xE1V\aX\xCCPT\x00\xD6\xA4f\xB2d\xE6\x1Es^Q\x14N\xD5\x9D\xE2\xC8\x89#4\\n`(:\x04\x80 \b\xF8\xA6\xF9\xA8~\xAC\x9A\x15O\xAC@\x14\xC5\xCC\x18\x91*\x83\x11\xD8s\x18\xF6\xFF\rN7\x80,\xAB\xE5V\v,\xAB\x84\xEF|\x05\xD6-\x05AH\xD4\x83EP\x14\xC5\rt\xC4\xD7\x04\xBB\x83l\x7Fs;\x1F]\xF9\xE8\x9E:\x94\x14\x95P\xB3\xB9\x86\xD2\xE2\xD2\xF4\x8CI\x95\x8B\xCD\xF0\xB5\x9F\x80\xFF\x93{\xCB}\xA1\x12\x0E\xD4B\x91[\xAFv\x92\xAE\x03\x82\xDDA^\xDE\xF62m\x9DmI\xE9b\xB7\xD9\xA9\xDDR\xCB\xD4\x92\xA9I\xC9\xA7\xCD\xB9&X\xB6\x05\xBA\xFB\x92\x93\xAF\xF0\xC0\xC9\x9DPX\x10_3\xC9\x14_\xA2(\n\xDB\xDF\xDC\x9E\xB4\xF1\x00\xFD\x03\xFD\xBC\xBA\xFBU\xC2\x83\xE1\xA4\xDBL\x98\xDE\x01X\xF3b\xF2\xC6\x034\xDF\x82\xF5\xB5\xA0(\x9A*\x8D\x03N\xD5\x9D\x1Aw\xD8\xEB\xD1\xD6\xD9\xC6\xE1c\x87Sn\x972\xBF:\x00-\x81\xD4\xDB\xFD\xE3,\x1C\xFA\xB7\xA6X\xE3\x80#'\x8Eh\x84\xCCQ\x85\xF5'\xBB\xD9\xB97\xC0\x9E]\xAD<w4\x88}P\xEB\xCD\xF7\x8F\xBF\x8F\xA2\xE3\xE5\x8C\xA1(\xB0\xE7\xAF\xDAr\xD7\x10\xFC\xB6\t:>\x80\e\xA7\xE1\x95k`\xD1\xD1c\xF7\x9F5E\xE6\xB1?\x86\xA2C4\\n\xD0\b=\xFDa/k\xCE\x8C\x06O,\xBF\xD8\x8F\#$\xF3\xDA\xEA\xD8\x85\xA5\xB3\xAB\x93\x9B\xB7o\"*\"\r\r\r\x98L&rrr\x98;w.\x92$\x01\xD0\xD5\xD5E]]\x1D\xB2,c\xB1X\xF0\xF9|\x14\x16\x16\x02000\xC0\x993g\x88F\xA3\x98\xCDf\xBC^/\x1E\x8F\xE7\xEE\x05\x1A\xAE\xC1u\x9D\xA9\xB9\xB7\t\xD6\x8CY\xC6^\xFA\x04\x14\x01~\x1A\xB7&\x1D;\v\x91!\xF5Q9L\xCC\b\bv\x05G\x1FucYv\xA9_SVu%\x843$k\xCA\xDB\xEF\xB4\x93\x9F\x9F\xCF\xF4\xE9\xD3q:\x9D\x94\x96\x96b\xB3\xD9F\xEB\x1D\x0E\a^\xAF\x17I\x92\xF0x<8\x1C\x8E\xD1:\xAB\xD5\x8A\xD7\xEB\xC5\xE5r\xDD\xAD\xEB\x0F\xC1\xF1z\xF5\xEE_k\xD5\x1A_0\x04_\xD5<\xC4\xE0Y\x1D\xD9\xC1\b\xB4v\xC6\x14\xC58@V\xB4\x06\x81:\x05\xE2\x11\x00\xB3\x8E\xB8\x1C\x95Q\x14\x85I\x93&1k\xD6,\xACV+\xFD\xFD\xFD\xF0\xE3\x9D0o#r[\x10I\x92\x989s&\x92$\xA9u5;`\xFE&\x94;=8\x9DNf\xCC\x98AAA\x81Z\xF7\xD2.\xA8~\x1E\x0E\xFE\x13\xA2:\x17\xCC\x91\x87\x03\xFA8\xAC\xFA\xB6\x10\x89\xBD\xC11S\xC0%\xB9\x10\x04A3\x8F?\xF4\xE6\xB2\xFCb\xEC(h\xF4X\t\xDA5K\bn\x97\e\xBB\xDD>\xFA\xDB\xE9t\xAA\xFF||\x13\xAE\x05\xB0F\xA2X\xF3\xF2\xB4uW[1G\xA2H\x93]\xB1\x1D\xAE^\f\x1F\xDF\x82E\xB3\xE1N\x8F\xD6\xA0V+\x9C\x94\xE0sq\xC1\xEC\xC1\xC9ZY\x93\tJb\xCBc\x1C`\xB5X\xF1M\xF3\xE1\xBF\xEA\x8F\x11\xDA\xBF$\x1FGH\xA6\xEAJ\ba\xD8\xF8\x1D_\x8CS\x14\xC8s\xE4Q\xE6)\xD3^\x18\xE0\xED\x9F\xA9\xC3Yrh\xEB\xDE\xD9\x9A\xB8n\xE5\"\xF5\x0F\xA0\xAC\x10&\xE7C{W\xAC\xCC\xB7f\xC2\xEF\xFC\xB0\xB8\e\x14\xE0\xDD\xC9\xF0\xC3\nm_\x8B\x1F\x86\xDC\xD8\x10\xDE\x1C/S\xFDX\xB5\xC6\x01\xFDV\x81\xD7V\xBBq\x84\x15,QE\xF7\xCE\x03TWUc2\xE9\xD7a\x16\xF5\r\x1C\xAFn,\xA2\t\xBE\xF9$\xEC8\x18[~5\x17\x96\xCC\x87\xE2A\b\x99 \xA81Ke\xC3*M\x91F\xDB\x15O\xAC\xA0\xA4\xA8D\xB7}_\x8E\x90\xD0x\xA7\xDD\xC9\x9A\x95k\xC6\xB1 \x03\xBC\xB8\x11\\N\xFD\xBAVkb\xE3\xE7U\xC0\xE6/k\x8A5\xD6\x88\xA2H\xCD\xE6\x1A\xEC6\xBBF8\x11\xA2Id\xCB\xA6-HN)\xE96\x13\xA6\xC8\xADN'1\xC1H\xD3#\xDF\x01\x7F|E\x1Diq\xE8\xF6RZ\\J\xED\x96Z\xA6\xB8\xA7\x8C\xDB\xB7\xC3\xEE\xE0\x85\xE7^`\xFE\xEC\xF9\xC9+\x94._z\x1C\xFE\xF2\x8B\xC4#a,\xD3K\xE0_\xAF\xC3l\xFD}J\xC2\xDD @x0\xCC\xE1c\x879z\xF2(\xEDw\xDAc\xEA\xF2\x1Cy,Y\xB4\x84\xB5\xAB\xD6f\xE7\xCE\xEBq\xFB\x0E\xFC|?\xBC\xFD\x9Eva\x9CV\f\xCF>\x05?\xF8\x06\xD8s\x13\xF5\xA0\xBF\e\xD4\xE3F\xE0\x06\xED\x9D\xEDD\xE5(n\x97\x9B\xA9\x9E\xA9\x89\x17\xBCl\x13\x95\xA1\xFE\x8A\x1A%\x9AE(\xF7$\xBC\xE3q$\xEF\x80D\xF8\x9B\xFD4_of\xD5\x92U\b\x89\x13\x0F\x0F*\x93\x12,\x99\xC9\xB3\xEF\xD0>._\xBB\xCC<\xDF\xBC\xAC&E\x82\xC1\xE0h\xC0&\xCB2.\x97kB\x99\xA9\xB4\x1D\xF0\xCC\xDAgh\xBE\xDE\xCCCE\x0F\xA5\xDBUJD\xA3Q\x1A\e\e\xE9\xE9\xE9\xC1\xE7\xF3QP\xA0Iv$E\xDAS\xE0~\x11\b\x04\xE8\xE8\xE8\xC0l6#\x8A\"\xE5\xE5\xE5\x13\x19\x01\xE9\xAF\x01\x00~\xBF\x9F\xE6\xE6f\x04A\xA0\xAC\xAC\x8C9s\xE6\xA4\xD3]6I\x7F\r\x00F\xB7\xBF\xE1p\x98\xDC\xDC\x84\x8F\x9C\fR\x03\xD8\x81\xADi\xF7\xF4)\x9C\x02C\x80\e\xC8\x05n\xA7\xDBYfF@v1\x03g\xC8\xC0\xFA\r$\b\x85'\x8A,\xCB\xD4\xFE\xBA\x96m{\xB7e\xB2[\x1Df\x02\xD33\xD2SFG\x80\xAC\xC8\xB4\xB6\xB5\xD2\xD7\x9FB\xCA:I.]\xBA\xA4f\x88P\xDFL-X\xB0 #\x81W\xC6\xD7\x80\xF0`\x18\x93`\xC2b\xC9\xEC[\xF6\xBE\xBE>\x9A\x9A\x9A\b\x85B\xF8|>\xDCnw&\x1C\x90\xF95@4\x89\xB4\xB4\xB4\x8C*g\xB7\xDB)**J\xBB\xDF\x96\x96\x16L&\x13\x0E\x87\x83\x96\x96\x16\xDCn\xDDW])\x93q\a\x98L&\xECv;~\xBF\x1F\xA7\xD39\x9A\xF2N\x8F\bs\xE6\xCCF?\xFB\x99\x1E\x19\xDF\xCE)\x8AB__\x1F\xA5\xA5\xA5H\x92D__\xBA\xEBA/P\x0Eh\xD3Y\x99 \xF3S@\x14\xF1z\xBD\x99\xEC\x11\x90\x80\x89\xC5\xFA\xE3a\xF8\x86\xFE\xC8\xC9#l}}+=}:)\xED\xA4\xB0\x01\r\xC0\x1F2\xA8\xD5]\fw\xC0\x85\xC6\v\\l\xBAH\xC7\x9D\a3\xD84<\x14\x0E\x0F\x86\xE9\fv\xE2)\xF4\x8C/<\x86`0H]]\x1D\x81@\x80\x82\x82\x02*++\x992e\xFC\x1Ce\x8A\x18\x1F\n\xE7Xs\x10\x11\t\x04\xD4W\xDA\xB2,\xC7\xBE\xF0L\x80\xD9l\xA6\xA2\xA2\x02\xB7\xDB\x8D\xD5j5l\x93\x95\x95\xBD\x80\xD9l\xA6\xB1\xB1\x91\xC1\xC1A|>\x1F\x8A\xA2\x8C\e\xC4\x88\xA2\x88\xCDf#??\x1F\x87\xC3aX\xBA-+\x0E\x18\x18\x18\xC0\xE5R\xDF;\x0E\f\f$\xE1\x80\xF3\xD8l\xEFa\xB3}\x1F0\xF64\xDA\x03\xBA\x1D^\a\xFC\t\xF8;\xF0\xA4\x91\x17\xBA_\xDBa\x19\xB8\x00\x8C\x9C\xF0\x9A\n\xCC\xE3\xEEC\xA9\x16\xF8<\xB0\xD4pM\xB2<\x02:\x81_\x02o\x01\xF1\xE7|\x8A\x80o\x03?\xC2\xA8\xA0G\x87\xCC\xE4\x04\x93\xE3?\xC0\xD3\x8C\x9F\xC5)\x02\xDEA\x1D\x01\x86\xA3=&g\f'Pc\xF9dRX\x01`%\xF0\x81\xA1\x1A\x8D\x90\x05\a\xF4\x00_\aB)\xB4\t\r\xB7\xE9\x1DO0m\xB2\xE0\x80m\xC0-\xDD\x9A\xEE\xDE\x1C\xBA{s\x12\xB4\xBB\x01l7J\xA9Q\xB2\xB0\x06\xCC\x02\x9AbJ\x82\xDD\xB9\xFCf\xFF\xE3\\\xF0\xAB\x89\x92Gf\xB5\xF2\xBD\x8D\xA7\xC9\xCF\x8B\x1F%3\x00?\x06b\xF4\x1Ap\x9Dx\xE3\x01v\xFF~\xD1\xA8\xF1\x00\xF5\x8D\xC5\xEC:\xB0P\xA7\xFDe\xD4\x91`\x1C\x06;@\xAB|$\"r\xEE\x92v/p\xAE\xC1C$\xA2\xF7j\xEB\xBA\x01z\xDD\xC5`\ah\xE3,\x93(#\x8A\xDA3|fQ\xC1\xA4Snt(l\xB0\x03\xCA\x88\xCF\xE3\x89&\x85\xEA\xAA\xAB\x1A\xC9\xA5UW\x11M\xF1\a2\x85\xE1>\x8C\xC3\xE0P\xB8\x10\xA8\x04\xCE\xC6\x94nZw\x0E\xAB%\xCA\xF1\xFF\xAA\xA78\x96,la\xFDS\xF5:\xED\x17\x02:\a\x1E3H\x16\x9E\x02o\x00\xCFO\xB0\xEDN\xE0\xBB\x19\xD4EC6B\xE1\bP\x05\x9CO\xB1]%p\x1A\x83\ai6Ba\vp\b5\xC6O\x96b\xE0]\xB2\x91\xAE\xC8\xD2^\xA0\x025\xB6_\x94\x84l\xD5\xB0l\xB9\x91\n\x8D\x92\xC5sn\xD3P\r{\vXN\xEC\xDD5\x03+\x80}\xC0I\xD4\xFC@vH\xFA\xC3\xC9\xCC\x13\x06F>j\xF0`\xF4\xF3>\x01\xD2\xC8\xA7\xB3\xE7\xF9\xEC|7<B\x9D \b\x95#S`\x03\xA9/\xD3\x9Ff\xEA\x80\x8D\x10\x17\xA6}\x16?\x9F\xFF\x1F<t\xF7\x13\xA9\x8B}(\x00\x00\x00\x00IEND\xAEB`\x82"

$dark = true if ARGV[0] == "dark"
$keys = Hash.new


# I2CP Settings
# $i2cpsettings["i2cp.username"] = ""
# $i2cpsettings["i2cp.password"] = ""
# $i2cpsettings["i2cp.SSL"] = "true

$i2cpsettings["inbound.backupQuantity"] = 1
$i2cpsettings["outbound.backupQuantity"] = 1
$i2cpsettings["inbound.length"] = 3
$i2cpsettings["outbound.length"] = 3
$i2cpsettings["inbound.quantity"] = 2
$i2cpsettings["outbound.quantity"] = 2

def unpackKey packedkey, remname
  $keys[remname] = OpenSSL::PKey::RSA.new packedkey.chars.map { |c| c == "|" ? "\n" : c }.join
end

def receiveEncHandler from, enc, push = true
  mat = /(.*) ;verify=(.*);/.match enc
  content = $privkey.private_decrypt mat[1].split(" ").map { |x| x.to_i }.pack("c*")
  veri = $keys[from].verify $digest, mat[2].split(" ").map { |x| x.to_i }.pack("c*"), mat[1]
  receiveHandler from, content, push, veri
end

def receiveHandler from, content, push = true, veri = nil
  msg = "#{from} #{veri == nil ? (push ? "[u]" :"[m]") : "[" + (veri ? "v" : "i") + "]"}, #{Time.new.strftime("%d/%m/%Y %H:%M")}: #{content}"
  $msgs[from] = "#{msg}\n#{$msgs[from]}"
  if $current == from
    $msgBox.text = "#{msg}\n#{$msgBox.text}"
  elsif push
    Thread.new {
      old = $consoleLabel.text
      $consoleLabel.text = "New message from #{from}"
      sleep 2
      $consoleLabel.text = old
    }
  end
end

def putsHash remname
  hash = Digest::SHA512.base64digest $keys[remname].to_s
  $msgs[remname] = "[i2prm], #{Time.new.strftime("%d/%m/%Y %H:%M")}: The hash of contact #{remname} is #{hash}.\n#{$msgs[remname]}"
  if $current == remname
    $msgBox.text = "[i2prm], #{Time.new.strftime("%d/%m/%Y %H:%M")}: The hash of contact #{remname} is #{hash}.\n#{$msgBox.text}"
  end
end

def randomcode len=32
  symbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
  res = ""
  rnd = Random.new
  for i in 0...len
    res += symbols[rnd.rand(0...symbols.length)]
  end
  return res
end

def textBoxDark obj, bg = Fox.FXRGB(26, 26, 26)
  obj.backColor = bg
  obj.textColor = Fox.FXRGB(255, 255, 255)
  obj.cursorColor = Fox.FXRGB(255, 0, 0)
  obj.selTextColor = Fox.FXRGB(204, 204, 204)
  obj.selBackColor = Fox.FXRGB(51, 0, 0)
end

def labelDark obj, nativeBg = Fox.FXRGB(0, 0, 0)
  obj.backColor = nativeBg
  obj.textColor = Fox.FXRGB(242, 242, 242)
end

def buttonDark obj
  obj.backColor = Fox.FXRGB(26, 26, 26)
  obj.textColor = Fox.FXRGB(255, 255, 255)
end

class MsgWindow < Fox::FXMainWindow
  
  include Fox
  
  def initialize app
    super(app, "Messages", :width=>640, :height=>410)
    
    self.icon = $icon
    self.miniIcon = $icon
    
    mainFrame = FXHorizontalFrame.new self, :opts => LAYOUT_FILL
    
    listFrame = FXVerticalFrame.new mainFrame, :opts => LAYOUT_FILL_Y
    $contactsBox = FXList.new listFrame, :opts => LAYOUT_FILL_Y|LIST_SINGLESELECT|LAYOUT_FILL_X
    closeButton = FXButton.new listFrame, "Close conversation"
    blockButton = FXButton.new listFrame, "Block user"
    unblockButton = FXButton.new listFrame, "Unblock user"
    
    msgFrame = FXVerticalFrame.new mainFrame, :opts => LAYOUT_FILL
    $msgBox = FXText.new msgFrame, :opts => LAYOUT_FILL|TEXT_AUTOSCROLL
    $msgBox.editable = false
    
    $b64ShowBox = FXTextField.new msgFrame, 60, :opts => LAYOUT_FILL_X
    $b64ShowBox.editable = false
    
    sendFrame = FXHorizontalFrame.new msgFrame
    sendtextBox = FXTextField.new sendFrame, 51, :opts => LAYOUT_FILL_X
    sendButton = FXButton.new sendFrame, "Send"
    usendButton = FXButton.new sendFrame, "U"
    
    if $dark
      mainFrame.backColor = Fox.FXRGB(0, 0, 0)
      $contactsBox.backColor = Fox.FXRGB(26, 26, 26)
      $contactsBox.textColor = Fox.FXRGB(255, 255, 255)
      $contactsBox.selBackColor = Fox.FXRGB(0, 77, 0)
      msgFrame.backColor = Fox.FXRGB(0, 0, 0)
      textBoxDark $msgBox
      textBoxDark $b64ShowBox
      sendFrame.backColor = Fox.FXRGB(0, 0, 0)
      textBoxDark sendtextBox
      sendtextBox.backColor = Fox.FXRGB(13, 13, 13)
      buttonDark sendButton
      buttonDark usendButton
      buttonDark closeButton
      buttonDark blockButton
      buttonDark unblockButton
    end
    
    $contactsBox.connect SEL_COMMAND do |sender, sel, index|
      $current = $contactsBox.getItem(sender.currentItem).text
      $msgBox.text = $msgs[$current].nil? ? "":$msgs[$current]
      $b64ShowBox.text = $b64ss[$current]
    end
    
    sendButton.connect(SEL_COMMAND) { sendHandler sendtextBox }
    usendButton.connect(SEL_COMMAND) { sendHandler sendtextBox, false }
    
    closeButton.connect SEL_COMMAND do
      if $current != ""
        $sockss[$current].close
      end
    end
    
    blockButton.connect SEL_COMMAND do
      $blocklist << $b64ss[$current]
    end
    
    unblockButton.connect SEL_COMMAND do
      $blocklist.delete $b64ss[$current]
    end
    
    sendtextBox.connect(SEL_CHANGED) do
      Thread.new(sendtextBox) { |sendtextBox|
        if sendtextBox.text[-1] == ";"
          sendtextBox.text = sendtextBox.text.delete_suffix ";"
          sendHandler sendtextBox
        end
      }
    end
  end
  
  def sendHandler sendtextBox, enc = true
    if $current == ""
      $consoleLabel.text = "Please select a nickname."
      return
    end
    
    sock = $sockss[$current]
    if sock.closed?
      $consoleLabel.text = "#{$current} is offline."
    else
      #begin
        if enc
          codmsg = $keys[$current].public_encrypt(sendtextBox.text).bytes.join " "
          sock.puts "I have an encrypted message for you - #{codmsg} ;verify=#{$privkey.sign($digest, codmsg).bytes.join " "};"
        else
          sock.puts "I have a message for you - #{sendtextBox.text}"
        end

      #rescue
      #  $consoleLabel.text = "#{$current} is offline."
      #end
      receiveHandler $current, sendtextBox.text, false
      sendtextBox.text = ""
    end
  end
  
  def create
    super
    show(Fox::PLACEMENT_SCREEN)
  end
end

    
class OptionsWindow < Fox::FXMainWindow
  
  include Fox
  
  def initialize app
    super(app, "I2P Row Messanger", :width=>335, :height=>145)
    
    self.icon = $icon
    self.miniIcon = $icon
    
    bgColor = Fox.FXRGB(13, 13, 13)
    tbBgColor = Fox.FXRGB(26, 26, 26)
    self.backColor = bgColor if $dark
    
    nicknameFrame = FXHorizontalFrame.new self, :padBottom => 3
    nicknameBoxLabel = FXLabel.new nicknameFrame, "Nickname:"
    nicknameBox = FXTextField.new nicknameFrame, 20, :opts => LAYOUT_FILL_X
    nicknameBox.text = randomcode 7
    connectButton = FXButton.new nicknameFrame, "Connect"
    if $dark
      connectButton.borderColor = Fox.FXRGB(0, 255, 255)
      connectButton.shadowColor = Fox.FXRGB(255, 0, 255)
      buttonDark connectButton
    else
      connectButton.borderColor = Fox.FXRGB(255, 0, 0)
      connectButton.shadowColor = Fox.FXRGB(0, 255, 0)
    end
    
    b64Frame = FXHorizontalFrame.new self, :padBottom => 3, :padTop => 0
    b64BoxLabel = FXLabel.new b64Frame, "Your base64:"
    b64Box = FXTextField.new b64Frame, 11, :opts => LAYOUT_FILL_X
    b64Box.editable = false
    
    hashLabel = FXLabel.new b64Frame, "Your Hash:"
    hashBox = FXTextField.new b64Frame, 6, :opts => LAYOUT_FILL_X
    hashBox.editable = false
    hashBox.text = Digest::SHA512.base64digest $pubkey.to_s
    
    addFrame = FXHorizontalFrame.new self, :padBottom => 0, :padTop => 1.5
    cb64BoxLabel = FXLabel.new addFrame, "Contact's base64: "
    cb64Box = FXTextField.new addFrame, 13, :opts => LAYOUT_FILL_X
    addContactButton = FXButton.new addFrame, "Add contact"
    addContactButton.disable
    
    
    $statusLabel = FXLabel.new self, "Status: Disconnected", :padBottom => 0, :padTop => 5, :padLeft => 15
    $consoleLabel = FXLabel.new self, "Console: ", :padTop => 0, :padLeft => 15
    
    if $dark
      nicknameFrame.backColor = bgColor
      labelDark nicknameBoxLabel, bgColor
      textBoxDark nicknameBox, tbBgColor
      b64Frame.backColor = bgColor
      labelDark b64BoxLabel, bgColor
      textBoxDark b64Box, tbBgColor
      addFrame.backColor = bgColor
      labelDark cb64BoxLabel, bgColor 
      textBoxDark cb64Box, tbBgColor
      buttonDark addContactButton
      labelDark $statusLabel, bgColor
      labelDark $consoleLabel, bgColor
    end
    
    connectButton.connect(SEL_COMMAND) { connectHandler connectButton, nicknameBox, b64Box, addContactButton }
    app.addSignal("SIGINT") {
      $sigintcounter += 1
      if $sigintcounter < 3
        connectHandler connectButton, nicknameBox, b64Box, addContactButton if $statusLabel.text == "Status: Connected"
        exit
      else
        exit!
      end
    }
    
    addContactButton.connect(SEL_COMMAND) { addHandler cb64Box, addContactButton }
  end
  
  def addHandler cb64Box, addContactButton
    
    Thread.new {
      begin
        Thread.new {
          addContactButton.disable
          sleep 4
          addContactButton.enable
        }
        sock = TCPSocket.new "127.0.0.1", 2005
        sock.puts cb64Box.text
        ans = sock.gets.chomp
        if ans[0..7] != "Hi. I am"
          sock.puts "Your answer caused a protocol error. I will now disconnect."
          $consoleLabel.text = "protocol error: ans"
          sock.close
          Thread.current.exit
        end
        remname = ans[10..-20]
        sock.puts "I want to talk to you."
        if ($consoleLabel.text = sock.gets.chomp) != "What is your b64?"
          sock.puts "Your answer caused a protocol error. I will now disconnect."
          sock.close
          Thread.current.exit
        end
        sock.puts $myb64
        #p $myb64
        sleep 0.5

        if ($consoleLabel.text = sock.gets.chomp) != "I will send you a verification message."
          sock.puts "Your answer caused a protocol error. I will now disconnect."
          sock.close
          Thread.current.exit
        elsif $consoleLabel.text == "Your base64 is blocked. I will now disconnect."
          $consoleLabel.text = "Your base64 address will be blocked."
          sock.close
          Thread.current.exit
        end
        if ($consoleLabel.text = sock.gets.chomp) != "What is your code?"
          sock.puts "Your answer caused a protocol error. I will now disconnect."
          sock.close
          Thread.current.exit
        end

        timer = 0
        while $codes[remname].nil? or timer == 20
          sleep 0.5
          timer += 1
        end

        sock.puts $codes[remname]
        $codes.delete remname
        #p $codes
        if ($consoleLabel.text = sock.gets.chomp) != "Your code is valid. What is your name?"
          sock.close
          Thread.current.exit
        end
        sock.puts $nickname

        if ($consoleLabel.text = sock.gets.chomp) != "Now send me a verification message."
          sock.close
          Thread.current.exit
        end

        code = randomcode $codelen
        clifc = TCPSocket.new "127.0.0.1", 2005
        clifc.puts cb64Box.text
        clifc.puts "Your code from _#{$nickname}_ is _#{code}_."
        sleep 0.5
        clifc.close

        sock.puts "I Agree."
        ans = sock.gets.chomp
        if ($consoleLabel.text = ans[0..9]) != "My code is"
          sock.puts "Your answer caused a protocol error. I will now disconnect."
          sock.close
          Thread.current.exit
        end
        if ($consoleLabel.text = ans[12..-2]) != code
          sock.puts "Your code is invalid. I will now disconnect."
          sock.close
          Thread.current.exit
        else
          sock.puts "Your code is valid."

          unless $msgs[remname].nil?
            remname += randomcode 3
          end
          if ($consoleLabel.text = sock.gets.chomp) != "What is your public key?"
            sock.close
            Thread.current.exit
          end
          sock.puts $sendpubkey
          if ($consoleLabel.text = sock.gets.chomp) != "I have received your public key and will now send my public key."
            sock.close
            Thread.current.exit
          end
          unpackKey sock.gets.chomp, remname
          sock.puts "I have received your public key."

          $msgs[remname] = ""
          $sockss[remname] = sock
          $contactsBox.appendItem(remname)
          $consoleLabel.text = "Ready. Recived public key: #{! $keys[remname].nil?}"
          $b64ss[remname] = cb64Box.text
          putsHash remname

          loop do
            begin
              if (msg = sock.gets).nil? == false
                msg = msg.chomp
                  if msg[0..26] == "I have a message for you - "
                    receiveHandler remname, msg[27..-1]
                  elsif msg[0..37] == "I have an encrypted message for you - "
                    receiveEncHandler remname, msg[38..-1]
                  end
                end
              rescue
                if sock.closed?
                  ind = $contactsBox.findItem remname
                    if ind != -1
                      $contactsBox.removeItem ind
                    end
                    $msgBox.text = ""
                    $current = ""
                    $b64ShowBox.text = ""
                    Thread.current.exit
                  end
              end
            end
          end
      rescue Exception => e
        $consoleLabel.text = e.message
        $logio.write e.full_message
      end
      }
  end

  def abortConnecting errmsg, nicknameBox, connectButton
    $consoleLabel.text = errmsg
    $logio.write errmsg
    nicknameBox.editable = true
    connectButton.text = "Connect"
    $statusLabel.text = "Status: Disconnected"
  end
  
  def connectHandler myself, nicknameBox, b64Box, addContactButton
    if myself.text == "Connect"
      $statusLabel.text = "Status: Connecting..."
      nicknameBox.editable = false
      $nickname = nicknameBox.text
      if $nickname == ""
        abortConnecting "Please enter a nickname.", nicknameBox, myself
        return
      end
      
      $serv = Thread.new do
        
        begin
          $cli = TCPSocket.new "127.0.0.1", 2827
        rescue Errno::ECONNREFUSED => e
          abortConnecting e.message, nicknameBox, myself
          $logio.write e.full_message
          Thread.stop
        end
        
        $consoleLabel.text = $cli.gets.chomp
        $consoleLabel.text = $cli.gets.chomp
        
        $cli.puts "setnick i2pm"
        $consoleLabel.text = $cli.gets.chomp
        
        $i2cpsettings.each_pair { |set, val|
          $cli.puts "option #{set.to_s}=#{val.to_s}"
          $consoleLabel.text = $cli.gets.chomp
        }
        
        if $db.has_key? "i2p-keys"
          $cli.puts "setkeys #{$db["i2p-keys"]}"
          myb64 = $cli.gets.chomp
          b64Box.text = myb64[3..-1]
          $myb64 = myb64[3..-1]
        else
          $cli.puts "newkeys"
          myb64 = $cli.gets.chomp
          b64Box.text = myb64[3..-1]
          $myb64 = myb64[3..-1]
          
          $cli.puts "getkeys"
          $db["i2p-keys"] = $cli.gets.chomp[3..-1]
        end
        
        
        $consoleLabel.text = myb64
        $cli.puts "outhost 127.0.0.1"
        $consoleLabel.text = $cli.gets.chomp
        $cli.puts "outport 2004"
        $consoleLabel.text = $cli.gets.chomp
        $cli.puts "inhost 127.0.0.1"
        $consoleLabel.text = $cli.gets.chomp
        $cli.puts "inport 2005"
        $consoleLabel.text = $cli.gets.chomp
        $cli.puts "start"
        $consoleLabel.text = $cli.gets.chomp
        $statusLabel.text = "Status: Connected"
        
        addContactButton.enable
              
        serv = TCPServer.new "127.0.0.1", 2004
        loop do
          Thread.new(serv.accept) { |sock|
            begin
              sock.gets
              sock.puts "Hi. I am _#{$nickname}_ What do you want?"
              wanted = sock.gets.chomp
              if wanted[0..14] == "Your code from "
                mat = /Your code from _(.*)_ is _(.*)_./.match(wanted)
                $codes[mat[1]] = mat[2]
                sock.close
                Thread.current.exit
              end

              $consoleLabel.text = "Incoming connection"

              sock.puts "What is your b64?"
              b64 = sock.gets.chomp
              $cli.puts "verify #{b64}"
              if $blocklist.include? b64
                sock.puts "Your base64 is blocked. I will now disconnect."
                $consoleLabel.text = "#{remname} tried to connect. It was blocked."
                sock.close
                Thread.current.exit
              end
              if $cli.gets.chomp[0..2] != "OK"
                sock.puts "Your b64 is invalid. I will now disconnect."
                sock.close
                Thread.current.exit
              end
              sock.puts "I will send you a verification message."

              code = randomcode $codelen
              clifc = TCPSocket.new "127.0.0.1", 2005
              clifc.puts b64
              clifc.puts "Your code from _#{$nickname}_ is _#{code}_."
              sleep 0.5
              clifc.close

              sock.puts "What is your code?"
              codein = sock.gets.chomp
              if code != codein
                sock.puts "Your code is invalid. I will now disconnect."
                sock.close
                Thread.current.exit
              end
              sock.puts "Your code is valid. What is your name?"
              remname = sock.gets.chomp
              sock.puts "Now send me a verification message."
              if sock.gets.chomp != "I Agree."
                sock.puts "Your answer caused a protocol error. I will now disconnect."
                sock.close
                Thread.current.exit
              end

              $consoleLabel.text = "Incoming connection from #{remname}"

              timer = 0
              while $codes[remname].nil? or timer == 20
                sleep 0.5
                timer += 1
              end
              sock.puts "My code is _#{$codes[remname]}_"
              if sock.gets.chomp != "Your code is valid."
                sock.close
                Thread.current.exit
              end
              $codes.delete remname

              unless $msgs[remname].nil?
                remname += randomcode 3
              end
              sock.puts "What is your public key?"
              unpackKey sock.gets.chomp, remname
              sock.puts "I have received your public key and will now send my public key."
              sock.puts $sendpubkey
              if sock.gets.chomp != "I have received your public key."
                sock.puts "Your answer caused a protocol error. I will now disconnect."
                sock.close
                Thread.current.exit
              end

              $msgs[remname] = ""
              $sockss[remname] = sock
              $contactsBox.appendItem(remname)
              $consoleLabel.text = "Ready. Recived public key: #{! $keys[remname].nil?}"
              $b64ss[remname] = b64
              putsHash remname

              ## waiting
              loop do
                begin
                  if (msg = sock.gets).nil? == false
                    msg = msg.chomp
                    if msg[0..26] == "I have a message for you - "
                      receiveHandler remname, msg[27..-1]
                    elsif msg[0..37] == "I have an encrypted message for you - "
                      receiveEncHandler remname, msg[38..-1]
                    end
                  end
                rescue
                  if sock.closed?
                    ind = $contactsBox.findItem remname
                    if ind != -1
                      $contactsBox.removeItem ind
                    end
                    $msgBox.text = ""
                    $current = ""
                    $b64ShowBox.text = ""
                    Thread.current.exit
                  end
                end
              end
            rescue Exception => e
              $consoleLabel.text = e.message
              $logio.write e.full_message
            end
          }
        end
      end
      myself.text = "Disconnect"
    else
      $statusLabel.text = "Status: Disconnecting..."
      $cli.puts "stop"
      $consoleLabel.text = $cli.gets.chomp
      sleep 2
      $cli.puts "clear"
      $consoleLabel.text = $cli.gets.chomp
      $cli.puts "quit"
      $consoleLabel.text = $cli.gets.chomp
      
      $cli.close
      $serv.exit
      
      exit
    end
  end
  
  def create
    super
    show(Fox::PLACEMENT_SCREEN)
  end
end

app = Fox::FXApp.new

$icon = Fox::FXPNGIcon.new app, $icon

op = OptionsWindow.new app
msg = MsgWindow.new app
app.create
app.run

exit