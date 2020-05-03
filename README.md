i2prm is a peer-to-peer messenger that uses the I2P network. The BOB API is used to communicate with the I2P router. The messages can be encrypted again in addition to the I2P encryption.

## Download and install i2prm

1.  Install the Ruby interpreter. There is a manual on [ruby-lang.org](https://www.ruby-lang.org/en/downloads/)
2.  Install fxruby. First, a few components have to be installed in Ubuntu/Debian:  
    `sudo apt-get install g++ libxrandr-dev libfox-1.6-dev` command.  
    There's nothing to do with Windows.  
    To install the gem you can run `gem install fxruby` on the command line.
3.  Next you can download the current version on [BitBucket](https://bitbucket.org/marek22k/i2prm/downloads/) [[Mirror](https://test.mk16.de/scriptFiles/i2prm.rb)].
4.  If necessary, the i2prm.rb file must be extracted from the ZIP folder.
5.  The program can then be started from the command line with `ruby i2prm.rb`.

## How do I connect i2prm to the I2P network?

1.  Enter a nickname in the I2P Row Messenger window if necessary. This is freely selectable.  
    Anyone who knows your base64 can also determine your nickname. If you don't want to type  
    in, you can also leave the randomly generated nickname.
2.  Then click the "Connect" button and wait. Depending on how well the I2P router is integrated,  
    this process can take a little longer. When the process has been successfully completed,  
    the status changes to "Connected" and the message "OK tunnel starting" appears below.

## How do I connect to someone else?

1.  In the "I2P Row Messenger" window in the "Contact's base64:"  
    text box, enter the base64 address of the contact you want to add.
2.  Next click on _Add contact_.
3.  Wait a few seconds. This process can take up to a minute.
4.  *   The text "Ready. Receive public: true" should appear on the lower label.
    *   If the Java error "no route to host" appears, one of the two contacts is not  
        integrated enough in the I2P network. It's best to try again in a few  
        minutes. If it still doesn't work, restarting i2prm can sometimes help.
5.  If the connection process was successful, the nickname of the contact appears  
    next in the Contact List in the Messages window.

## How do I send a message?

1.  In the Messages window in the contact list, select the nickname to which you want to send a message.
2.  Enter the message in the bottom text box of the Messages window.
3.  *   To send the message encrypted, enter a symbol (`;`) in the text box or click on the "Send" button.
    *   To send the message unencrypted, click on the "U" button.

## How do I close a conversation?

1.  In the Messages window in the contact list, select the nickname of the  
    conversation at which you want to close the conversation.
2.  Then click on the "Close" button at the bottom right.

## The message `ERROR tunnel settings incomplete` appears.  
What can I do about it?

1.  This message often appears when i2prm has ended but the connection continues. To fix this  
    error, start the Ruby script with the argument "rescue" ie `ruby i2prm.rb rescue`.  
    This process takes a bit. Finally, the message "Complete!" appear.  
    The whole issue should look something like this:  
    `BOB API: OK Nickname set to i2pm  
    BOB API: OK tunnel stopping  
    BOB API: OK cleared  
    BOB API: ERROR no nickname has been set  
    BOB API: OK Bye!  
    Complete!`

## What does the v, i, m and u mean in square brackets in messages?

When an encrypted message is sent, it is automatically signed to  
confirm that it actually came from the sender. Unencrypted messages are not signed.

*   v(valid) means that the signature is valid.
*   i(invalid) means that the signature is invalid.
*   u(unencrypted) means that the message is unencrypted and therefore not signed.
*   m(me or myself) means that the message comes from yourself and is therefore also valid.

## How do I change the key strength?

The default strength is 4096 bytes.  
This key is used to encrypt, decrypt, sign and verify messages.

1.  Execute helper script editkeystrength.rb. As the first argument, enter the new desired key length.

** Attention: The old key will be deleted. **

## How do I change the length of the verification string?

**_Note: To change this, you have to change the source code of the program._**  
The connection partner is sent a verification string to confirm that it has  
transmitted its real base64\. The default length is 32 characters.

1.  Open the i2prm.rb file with any editor. However, I recommend using syntax highlighting for an overview.
2.  Find the line with the following content: `$codelen = 32`
3.  Replace the number 32 with the desired key length.


## How can I activate the BOB API?

To do this, go to the settings of your I2P router at http://127.0.0.1:7657/configclients
Under "BOB application bridge" you can see whether the BOB API has started and whether it is automatically started by the I2P router when it starts.
If you want to use i2prm more often, we recommend the option "Run at Startup?" to activate.