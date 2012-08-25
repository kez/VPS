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

leb() {
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

    IPS=`who | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'`
    if ! confirm 'Confirm your IP only has access via SSH.\n Or set which one(s)' $IPS; then
      IPS=$REPLY
    fi
    PORT=$((RANDOM+RANDOM%31744+1024))
    if ! confirm 'Confirm your ssh port.\n Or set which one' $PORT; then
      PORT=$REPLY
    fi
    echo privatessh $PORT/tcp >> /etc/services
    cat > /etc/xinetd.d/dropbear <<EOF
service privatessh
{
  socket_type = stream
  wait = no
  disable = no
  only_from = $IPS
  user = root
  server = /usr/sbin/dropbear
  server_args = -i -I 600
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
    ok 'dropbear installed (Check now your ssh connection before you drop this one).\n'
  fi



 # EDITS:
 if ! apt_installed mysql-server; then
    apt_install mysql-server
    ok 'mysql installed.\n'
  fi

  if ! apt_installed git; then
    apt_install git
    ok 'git installed.\n'
  fi

  if ! apt_installed sysbench; then
    apt_install sysbench
    ok 'sysbench installed.\n'
  fi

   if ! apt_installed build-essential; then
    apt_install build-essential
    ok 'build-essential installed.\n'
  fi


  if ! apt_installed python; then
    apt_install python
    ok 'python installed.\n'
  fi

  if ! apt_installed tmux; then
    apt_install tmux
    ok 'tmux installed.\n'
  fi

   if ! apt_installed nano; then
    apt_install nano
    ok 'nano installed.\n'
  fi

if ! apt_installed libreadline5-dev; then
    apt_install libreadline5-dev
    ok 'libreadline5-dev installed.\n'
  fi

  if ! apt_installed redis-server; then
    apt_install redis-server
    ok 'redis-server installed.\n'
  fi


}

lowendbox() {
  unneeded
  leb
}
