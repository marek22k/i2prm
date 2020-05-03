checki2prmdb.rb
---------------
* Function: Checks the validity of the keys in a .gdbm file
* Arguments: The .gdbm file which should be checked.
* Return: The result of whether the private and the I2P key are valid.

createi2prmdb.rb
----------------
* Function: Generates .gdbm files that can be used by i2prm. The files are saved as "i2prm.gdbm-[five random characters]".
* Arguments: Number of databases to be generated.
* Return: The status of the generation

readi2prmdb.rb
--------------
* Function: Outputs the content of a .gdbm file, i.e. the key for the encryption and the I2P key pair.
* Arguments: The .gdbm file which should be readed.
* Return: The content of a .gdbm file, i.e. the key for the encryption and the I2P key pair.

rmpubkeyfromi2prmdb.rb
----------------------
short for "remove public key from i2prm database"
* Function: i2prm was changed so that it only stores the private and not the public key in the .gdbm database file, since the public key can now be restored from the private. However, some old .gdbm database files can still contain the public key. This script removes this redundant information.
* Arguments: The .gdbm file; If not specified, the default name "i2prm.gdbm" is used.
* Return: The result or the current status

editkeystrength.rb
------------------
** Attention: The old key will be deleted. **
* Function: The script generates a new key for encrypting the messages.
* Arguments: The first argument is the new key strength. This must be greater than 512 bytes. The second argument is optional and specifies the .gdbm file. If no name is given, an attempt is made to read the "i2prm.gdbm" file.
* Return: The result or the current status