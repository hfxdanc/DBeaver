# DBeaver
Flatpak io.dbeaver.DBeaverCommunity with MariaDB, local socket and Kerberos

### MariaDB Configuration

#### Fedora

Create AD managed Service Account and Kerberos keytab for MariaDB.

`$ sudo sh -c 'umask 0077; mkdir /var/lib/user/mysql'`
`$ sudo chown mysql:mysql /var/lib/user/mysql`

`$ adcli create-msa --domain=<DOMAIN> --host-keytab=/var/lib/user/mysql/mysql.keytab --login-user=<AD Administrator>`

*or if MSA should be created in a separate OU*

`$ adcli create-msa --domain=<DOMAIN> --domain-OU='CN=Users,OU=Unix,DC=XXX,DC=XXX,DC=XXX' --host-keytab=/var/lib/user/mysql/mysql.keytab --login-user=<AD Administrator>`

Follow GSSAPI configuration instructions from https://mariadb.com/kb/en/authentication-plugin-gssapi/

`$ cat /etc/my.cnf.d/auth_gssapi.cnf` 
`[mariadb]`
`plugin-load-add = auth_gssapi.so`
`gssapi = FORCE`
`gssapi_principal_name = <principal created with adcli above>`
`gssapi_keytab_path = /var/lib/user/mysql/mysql.keytab`
`$`

------

#### Configure DBeaver

On Fedora use Gnome Software tool, search for "Dbeaver" and install (tested using the Flathub [User] install choice).  Follow this by searching for "MariaDB Client" and install.

- [ ] Launch DBeaver and create a new connection.

- [ ] Database --> New Database Connection --> MariaDB --> Next
- [ ] Connect by URL
- [ ] URL:  `jdbc:mariadb:///?connectTimeout=1000&localSocket=/var/lib/mysql/mysql.sock&servicePrincipalName=<service_principal_name>`
- [ ] Username: [clear]
- [ ] Uncheck "Save password locally"
- [ ] Click on "Finish"

Edit the new connection ...

- [ ] Connection Settings --> Shell Commands
- [ ] Select "Before Connect", add `/usr/bin/kinit -ki` to "Command:" and check "Wait for process to finish"
- [ ] Select "After Disconnect", add `/usr/bin/kdestroy` to "Command:"
- [ ] Click on "OK"

Edit driver to remove prompting for a password ...

- [ ] Database --> Driver Manager
- [ ] Select "MariaDB" and click on "Edit..."
- [ ] Check "No authentication"
- [ ] Click on "OK"
- [ ] Click in "Close"

------

##### Run from command line

`$ flatpak run --env="KRB5_CONFIG=/run/user/${UID}/krb5.conf" --env="KRB5_CLIENT_KTNAME=/run/user/${UID}/krb5.keytab" --env="KRB5CCNAME=FILE:/tmp/krb5cc_${UID}" --filesystem="xdg-run/krb5.conf" --filesystem="xdg-run/krb5.keytab" --filesystem="/var/lib/mysql/mysql.sock" --user io.dbeaver.DBeaverCommunity`

##### Run from Gnome launcher

Copy DBeaver script to local binaries directory, modify desktop launcher to point to script.

`$ cp DBeaver ~/.local/bin/`
`$ chmod +x ~/.local/bin/DBeaver`
`$ sed --in-place "s|^\(Exec=.*\)\$|#\1\nExec=$HOME/.local/bin/DBeaver|" ~/.local/share/flatpak/exports/share/applications/io.dbeaver.DBeaverCommunity.desktop`
`$ update-desktop-database ~/.local/share/flatpak/exports/share/applications`

------

##### Extras

Awk snippit (recursive) to expand Kerberos configuration "#includedir" directives.

`$ awk -f expand-conf.awk /etc/krb5.conf >$XDG_RUNTIME_DIR/krb5.conf`
