# Zimbra Scripts
Set of scripts and tools to increase your performance with ![alt text](https://www.zimbra.com/wp-content/uploads/2016/06/zimbra-logo-color-282-1.png "Zimbra Logo")

&nbsp;
## [Erase all mails send by an user link](delete_all_mails_from_user.sh)
Using the logs it finds the senders to whom the user sent mails and removes them. **Must be run as a Zimbra user.**

-u : Set the user to eliminate mails (*)

-l : Set the log path (Default: /var/log/)

-h : Print the help

```shell
./delete_all_mails_from_user.sh -u pepe@gmail.com
```
&nbsp;

## [Restore msg files ](restore_msg.sh)
Allows to restore a directory containing msg files to a specific mailbox. **Must be run as a Zimbra user.**

-u : Set the mailbox (*)

-s : Set the store path (*)

-d : Do not remove if exist mail (Default: true)

-h : Print the help

```shell
./restore_msg.sh -u pepe@gmail.com -s /home/pepe/mailbox -d
```
