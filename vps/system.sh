# ------------------------------------------------------------ #
# VPS Management : System +/- LEB style
#  - remove unneeded & rsyslogd
#  - install locales, htop, nano, syslogd, xinetd, dropbear
# ------------------------------------------------------------ #

unneeded() {
  for pkg in portmap 'apache2*' bind9 'samba*' nscd
  do
    if apt_installed $pkg; then
      apt_remove $pkg
      ok $pkg' removed.\n'
    fi
  done

  # rsyslogd allocate ~30Mo... Too much, we will use inetutils-syslog
  if which rsyslogd >/dev/null; then
    apt_remove rsyslog
    ok 'rsyslogd removed.\n'
  fi
}

basics() {
  if ! apt_installed locales; then
    apt_install locales
    ok 'locales installed.\n'
  fi

  if ! apt_installed htop; then
    apt_install htop
    ok 'htop installed.\n'
  fi

  if ! apt_installed nano; then
    apt_install nano
    ok 'nano installed.\n'
  fi

  if ! apt_installed inetutils-syslogd; then
    apt_install inetutils-syslogd

    invoke-rc.d inetutils-syslogd stop
    rm -rf /var/log/*.log /var/log/mail.* /var/log/news /var/log/debug /var/log/messages
    rm -rf /var/log/syslog

    cat > /etc/syslog.conf <<EOF
*.info;authpriv.none;cron.none -/var/log/messages
authpriv.* -/var/log/authpriv
cron.* -/var/log/cron
EOF
    cat > /etc/logrotate.d/inetutils-syslogd <<EOF
/var/log/cron
/var/log/authpriv
/var/log/messages
{
  rotate 4
  weekly
  missingok
  notifempty
  compress
  sharedscripts
  postrotate
    /etc/init.d/inetutils-syslogd reload > /dev/null
  endscript
}
EOF

    invoke-rc.d inetutils-syslogd start
    ok 'inetutils-syslogd installed and setup.\n'
  fi

  if ! apt_installed xinetd; then
    apt_install xinetd
    ok 'xinetd installed.\n'
  fi

  if !  apt_installed dropbear; then
    apt_install dropbear
    update-rc.d -f dropbear remove

    invoke-rc.d ssh stop

    IPS=`who | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'`
    if ! confirm 'Confirm your IP only has access via SSH.\n Or set which one(s)' $IPS; then
      IPS=$REPLY
    fi
    cat > /etc/xinetd.d/dropbear <<EOF
service ssh
{
  socket_type = stream
  only_from = $IPS
  wait = no
  user = root
  protocol = tcp
  server = /usr/sbin/dropbear
  server_args = -i -I 600
  disable = no
}
EOF

    if [ ! -f ~/.ssh/authorized_keys ]; then
      if yesno "Would you like to add your own public key?" Y; then
        [ -d ~/.ssh ] || mkdir ~/.ssh
        echo '# Replace this line by your own public key' > ~/.ssh/authorized_keys
        nano ~/.ssh/authorized_keys
      fi
    fi

    update-rc.d -f ssh remove

    invoke-rc.d xinetd restart
    ok 'dropbear installed.\n'
  fi
}

system() {
  unneeded
  basics
}