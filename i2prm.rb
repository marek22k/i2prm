
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
  
  $helptext = 'I2P Row Messenger (kurz i2prm) ist ein Nachrichtenvermittler für I2P.
Er benutzt das BOB API und verbindet sich Peer-to-Peer.
Beim Start von i2prm öffnen sich zwei Fenster, wobei das eine das andere verdeckt.
In dem einem Fenster "Messages" findet man rechts eine Liste mit den Kontakten. In
der Mitte den Chatverlauf. Die Textbox darunter beinhaltet die base64 des Kontaktes.
Darunter ist eine Textbox mit der man Nachrichten schreiben kann. Zum Absenden kann
man auf den "Send"-Button klicken. Um einen Kontakt zu entfernen kann man auf den
"Close-Button" klicken.
Zum Start vom i2prm generiert das Programm eine Datei mit dem Namen "keys.b64".
Diese Datei beinhaltet den öffentlichen und privaten Schlüssel für den Tunnel. Aus
dieser Datei wird dann auch die base64 erzeugt. Möchte man also eine andere base64
oder verschiedenen haben, kann man die Datei keys.b64 löschen bzw. umbenennen oder
verschieben.
Das andere Fenster beinhaltet die Tools um Verbindungen aufbauen zukönnen. In der
"Nickname"-Box gibt man einen individuellen Nicknamen ein. Wenn man keinen Eingeben
möchte, kann man aber auch die 7-stellige Zeichenfolge drinnen lassen. Danach klickt
man zum Verbinden auf den "Connect"-Button. Dies dauert eine Weile. Steht unten
"Status: Connected", hat der Messenger erfolgreich seine Tunnel hergestellt. Bei
"Your base64:" findet man seine eigene base64. Diese kann man dann z. B. mit
Freunden oder Bekannten teilen. Hat man von jemanden eine base64 erhalten und
möchte ihn kontaktieren, kann die die base64 bei "Contact*s base64:" hinzufügen.
Dann kann man auf "Add contact" klicken und eine Weile warten. Dies dauert bis zu
einer Minute. Wenn der Vorgang erfolgreich abgeschlossen ist, steht unter "Ready.".
Bei hinzufügen eines Kontaktes teilt man automatisch seine base64. Diese wird
wiederrum mit einem Code verifiziert. Dies regelt i2prm automatisch.'
  
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
$codelen = 32
$codes = Hash.new
$msgs = Hash.new
$current = ""
$sockss = Hash.new
$b64ss = Hash.new

def randomcode len=32
  symbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
  res = ""
  rnd = Random.new
  for i in 0...len
    res += symbols[rnd.rand(0...symbols.length)]
  end
  return res
end

class MsgWindow < Fox::FXMainWindow
  
  include Fox
  
  def initialize app
    super(app, "Messages", :width=>600, :height=>400)
    
    mainFrame = FXHorizontalFrame.new self, :opts => LAYOUT_FILL
    $contactsBox = FXList.new mainFrame, :opts => LAYOUT_FILL_Y
    
    msgFrame = FXVerticalFrame.new mainFrame, :opts => LAYOUT_FILL
    $msgBox = FXText.new msgFrame, :opts => LAYOUT_FILL|TEXT_AUTOSCROLL
    $msgBox.editable = false
    
    $b64ShowBox = FXTextField.new msgFrame, 60, :opts => LAYOUT_FILL_X
    $b64ShowBox.editable = false
    
    sendFrame = FXHorizontalFrame.new msgFrame
    sendtextBox = FXTextField.new sendFrame, 50
    sendButton = FXButton.new sendFrame, "Send"
    closeButton = FXButton.new sendFrame, "Close"
    
    $contactsBox.connect SEL_COMMAND do |sender, sel, index|
      $current = $contactsBox.getItem(sender.currentItem).text
      $msgBox.text = $msgs[$current].nil? ? "":$msgs[$current]
      $b64ShowBox.text = $b64ss[$current]
    end
    
    sendButton.connect(SEL_COMMAND) { sendHandler sendtextBox }
    
    closeButton.connect SEL_COMMAND do
      if $current != ""
        $sockss[$current].close
      end
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
  
  def sendHandler sendtextBox
    if $current == ""
      $consoleLabel.text = "Please select a nickname."
      return
    end
    
    sock = $sockss[$current]
    if sock.closed?
      $consoleLabel.text = "#{current} is offline."
    else
      begin
        sock.puts "I have a message for you - #{sendtextBox.text}"
      rescue
        $consoleLabel.text = "#{$current} is offline."
      end
      $msgs[$current] = "#{$nickname}, #{Time.new.strftime("%d/%m/%Y %H:%M")}: #{sendtextBox.text}\n" + $msgs[$current]
      $msgBox.text = "#{$nickname}, #{Time.new.strftime("%d/%m/%Y %H:%M")}: #{sendtextBox.text}\n" + $msgBox.text
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
    super(app, "I2P Row Messanger", :width=>600, :height=>100)
    
    nicknameFrame = FXHorizontalFrame.new self
    nicknameBoxLabel = FXLabel.new nicknameFrame, "Nickname:"
    nicknameBox = FXTextField.new nicknameFrame, 20
    nicknameBox.text = randomcode 7
    connectButton = FXButton.new nicknameFrame, "Connect"
    b64BoxLabel = FXLabel.new nicknameFrame, "Your base64: "
    b64Box = FXTextField.new nicknameFrame, 10
    b64Box.editable = false
    
    addFrame = FXHorizontalFrame.new self
    cb64BoxLabel = FXLabel.new addFrame, "Contact's base64: "
    cb64Box = FXTextField.new addFrame, 10
    addContactButton = FXButton.new addFrame, "Add contact"
    
    
    statusFrame = FXHorizontalFrame.new self
    $statusLabel = FXLabel.new statusFrame, "Status: Disconnected"
    $consoleLabel = FXLabel.new statusFrame, "Console: "
    
    
    connectButton.connect(SEL_COMMAND) { connectHandler connectButton, nicknameBox, b64Box }
    addContactButton.connect(SEL_COMMAND) { addHandler cb64Box }
  end
  
  def addHandler cb64Box
    
    sock = TCPSocket.new "127.0.0.1", 2005
    sock.puts cb64Box.text
    ans = sock.gets.chomp
    if ans[0..7] != "Hi. I am"
      sock.puts "Your answer caused a protocol error. I will now disconnect."
      $consoleLabel.text = "protocol error"
      sock.close
      return
    end
    remname = ans[10..-20]
    sock.puts "I want to talk to you."
    if ($consoleLabel.text = sock.gets.chomp) != "What is your b64?"
      sock.puts "Your answer caused a protocol error. I will now disconnect."
      sock.close
      return
    end
    sock.puts $myb64
    #p $myb64
    sleep 0.5
    
    if ($consoleLabel.text = sock.gets.chomp) != "I will send you a verification message."
      sock.puts "Your answer caused a protocol error. I will now disconnect."
      sock.close
      return
    end
    if ($consoleLabel.text = sock.gets.chomp) != "What is your code?"
      sock.puts "Your answer caused a protocol error. I will now disconnect."
      sock.close
      return
    end
    
    timer = 0
    while $codes[remname].nil? or timer == 20
      sleep 0.5
      timer += 1
    end
    
    sock.puts $codes[remname]
    #p $codes
    if ($consoleLabel.text = sock.gets.chomp) != "Your code is valid. What is your name?"
      sock.close
      return
    end
    sock.puts $nickname
    
    if ($consoleLabel.text = sock.gets.chomp) != "Now send me a verification message."
      sock.close
      return
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
      return
    end
    if ($consoleLabel.text = ans[12..-2]) != code
      sock.puts "Your code is invalid. I will now disconnect."
      sock.close
      return
    else
      sock.puts "Your code is valid."
      unless $msgs[remname].nil?
        remname += randomcode 3
      end
      $msgs[remname] = ""
      $sockss[remname] = sock
      $contactsBox.appendItem(remname)
      $consoleLabel.text = "Ready."
      $b64ss[remname] = cb64Box.text
      
      Thread.new {
        loop do
          begin
            if (msg = sock.gets).nil? == false
              msg = msg.chomp
                if msg[0..26] == "I have a message for you - "
                  $msgs[remname] = "#{remname}, #{Time.new.strftime("%d/%m/%Y %H:%M")}: #{msg[27..-1]}\n" + $msgs[remname]
                  if $current == remname
                    $msgBox.text = "#{remname}, #{Time.new.strftime("%d/%m/%Y %H:%M")}: #{msg[27..-1]}\n" + $msgBox.text
                  else
                    Thread.new {
                      old = $consoleLabel.text
                      $consoleLabel.text = "New message from #{remname}"
                      sleep 2
                      $consoleLabel.text = old
                    }
                  end
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
      }
    end
  end
  
  def connectHandler myself, nicknameBox, b64Box
    if myself.text == "Connect"
      $statusLabel.text = "Status: Connecting..."
      nicknameBox.editable = false
      $nickname = nicknameBox.text
      $serv = Thread.new do
        $cli = TCPSocket.new "127.0.0.1", 2827
        $consoleLabel.text = $cli.gets.chomp
        $consoleLabel.text = $cli.gets.chomp
        
        $cli.puts "setnick i2pm"
        $consoleLabel.text = $cli.gets.chomp
        
        
        if File.exist?("keys.b64")
          f = File.new("keys.b64")
          $cli.puts "setkeys #{f.gets.chomp}"
          f.close
          myb64 = $cli.gets.chomp
          b64Box.text = myb64[3..-1]
          $myb64 = myb64[3..-1]
        else
          $cli.puts "newkeys"
          myb64 = $cli.gets.chomp
          b64Box.text = myb64[3..-1]
          $myb64 = myb64[3..-1]
          
          f = File.new("keys.b64", "w")
          $cli.puts "getkeys"
          f.puts $cli.gets.chomp[3..-1]
          f.close
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
        
        serv = TCPServer.new "127.0.0.1", 2004
        loop do
          Thread.new(serv.accept) do |sock|
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
            
            unless $msgs[remname].nil?
              remname += randomcode 3
            end
            $msgs[remname] = ""
            $sockss[remname] = sock
            $contactsBox.appendItem(remname)
            $consoleLabel.text = "Ready."
            $b64ss[remname] = b64
            ## waiting
            loop do
              begin
                if (msg = sock.gets).nil? == false
                  msg = msg.chomp
                  if msg[0..26] == "I have a message for you - "
                    $msgs[remname] = "#{remname}, #{Time.new.strftime("%d/%m/%Y %H:%M")}: #{msg[27..-1]}\n" + $msgs[remname]
                    if $current == remname
                      $msgBox.text = "#{remname}, #{Time.new.strftime("%d/%m/%Y %H:%M")}: #{msg[27..-1]}\n" + $msgBox.text
                      else
                        Thread.new {
                          old = $consoleLabel.text
                          $consoleLabel.text = "New message from #{remname}"
                          sleep 2
                          $consoleLabel.text = old
                        }
                    end
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
      b64Box.text = ""
      nicknameBox.editable = true
      $contactsBox.clearItems
      myself.text = "Connect"
      $statusLabel.text = "Status: Disconnected"
    end
  end
  
  def create
    super
    show(Fox::PLACEMENT_SCREEN)
  end
end

app = Fox::FXApp.new
op = OptionsWindow.new app
msg = MsgWindow.new app
app.create
app.run

exit