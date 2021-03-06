#____________________________________________________________________
# File: hardening.pp
#____________________________________________________________________
#
# Author:  <sashby@dfi.ch>
# Created: 2015-04-01 14:39:03+0200
# Revision: $Id$
#
# Copyright (C) 2015
#
#--------------------------------------------------------------------

class xen::hardening {
  include ssh

  service { 'atd': ensure => stopped }

  # Manage shadow passwords:
  exec { 'login.defs PASS_MAX_DAYS':
    command => "/bin/sed -i -e 's/PASS_MAX_DAYS\t99999/PASS_MAX_DAYS   90/' /etc/login.defs",
    unless  => "/bin/grep 'PASS_MAX_DAYS   90' /etc/login.defs",
  }

  exec { 'login.defs PASS_MIN_DAYS':
    command => "/bin/sed -i -e 's/PASS_MIN_DAYS\t0/PASS_MIN_DAYS   7/' /etc/login.defs",
    unless  => "/bin/grep 'PASS_MIN_DAYS   7' /etc/login.defs",
  }

  exec { 'login.defs PASS_MIN_LEN':
    command => "/bin/sed -i -e 's/PASS_MIN_LEN\t5/PASS_MIN_LEN   9/' /etc/login.defs",
    unless  => "/bin/grep 'PASS_MIN_LEN   9' /etc/login.defs",
  }

  exec { 'login.defs PASS_WARN_AGE':
    command => "/bin/sed -i -e 's/PASS_WARN_AGE\t7/PASS_WARN_AGE   14/' /etc/login.defs",
    unless  => "/bin/grep 'PASS_WARN_AGE   14' /etc/login.defs",
  }

  exec { 'Check that shadow passwords are enabled and that login.defs has been modified':
    command => "/usr/sbin/pwconv",
    unless  => "/usr/bin/test -f /etc/shadow",
    require => [
                Exec['login.defs PASS_MAX_DAYS'],
                Exec['login.defs PASS_MIN_DAYS'],
                Exec['login.defs PASS_MIN_LEN'],
                Exec['login.defs PASS_WARN_AGE'],
                ],
  }

  # Modification of /etc/inittab to require passwords for single-user mode:
  exec { 'Modify single-user mode to require a password':
    command => "/bin/echo '~~:S:wait:/sbin/sulogin' >> /etc/inittab",
    unless  => "/bin/grep '~~:S:wait:/sbin/sulogin' /etc/inittab",
  }

  # For managing password history tracking:
  file { '/etc/security/opasswd':
    ensure => present,
    group  => 'root',
    mode   => '0600',
    owner  => 'root',
  }

  # Manage XAPI SSL source config:
  file { '/etc/init.d/xapissl':
    ensure => present,
  }

  # Replace the default SSL ciphers:
  exec { 'Replace default SSL ciphers in /etc/init.d/xapissl':
    command => "/bin/sed -i -e 's/ciphers = !SSLv2:RSA+AES256-SHA:RSA+AES128-SHA:RSA+RC4-SHA:RSA+RC4-MD5:RSA+DES-CBC3-SHA/ciphers = AES128+EECDH:AES128+EDH:AES256+EECDH:AES256+EDH:HIGH:3DES:!PSK:!MD5:!aNULL:!eNULL/' /etc/init.d/xapissl",
    unless  => "/bin/grep 'AES128+EECDH:AES128+EDH:AES256+EECDH:AES256+EDH:HIGH:3DES:!PSK:!MD5:!aNULL:!eNULL' /etc/init.d/xapissl",
    require => File['/etc/init.d/xapissl'],
    notify  => Service['xapi'],
  }

  service { 'xapi':
    ensure => running,
  }

  file { '/etc/sysconfig/iptables':
    ensure => present,
  }

  exec { 'XAPI ensure port 80 is closed':
    command => "/bin/sed -i -e 's/-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT//' /etc/sysconfig/iptables",
    onlyif  => "/bin/grep 'dport 80 -j ACCEPT' /etc/sysconfig/iptables",
    require => File['/etc/sysconfig/iptables'],
  }

  service { 'iptables':
    ensure    => running,
    subscribe => File['/etc/sysconfig/iptables'],
  }

  sysctl { 'net.ipv4.tcp_max_syn_backlog':
    ensure    => 'present',
    permanent => 'yes',
    value     => 4096,
  }

  sysctl { 'net.ipv4.conf.all.rp_filter':
    ensure    => 'present',
    permanent => 'yes',
    value     => 1,
  }

  sysctl { 'net.ipv4.conf.all.accept_source_route':
    ensure    => 'present',
    permanent => 'yes',
    value     => 0,
  }

  sysctl { 'net.ipv4.conf.all.secure_redirects':
    ensure    => 'present',
    permanent => 'yes',
    value     => 0,
  }

  sysctl { 'net.ipv4.conf.default.accept_redirects':
    ensure    => 'present',
    permanent => 'yes',
    value     => 0,
  }

  sysctl { 'net.ipv4.conf.default.secure_redirects':
    ensure    => 'present',
    permanent => 'yes',
    value     => 0,
  }

  sysctl {'net.ipv4.icmp_echo_ignore_broadcasts':
    ensure    => 'present',
    permanent => 'yes',
    value     => 1,
  }

  # Console modifications:
  exec { 'No automatic root login on console':
    command => "/bin/sed -i -e 's/autologin root/autologin nobody/' /opt/xensource/libexec/run-boot-xsconsole",
    onlyif  => "/bin/grep 'autologin root' /opt/xensource/libexec/run-boot-xsconsole",
  }

  exec { 'No auto login on console':
    command => "/bin/sed -i -e 's/-f root/-p/' /usr/lib/xen/bin/dom0term.sh",
    onlyif  => "/bin/grep -- '-f root' /usr/lib/xen/bin/dom0term.sh",
  }

  # Remove default Citrix landing page content:
  file { '/opt/xensource/www/Citrix-index.html':
    ensure  => present,
    content => '<html></html>',
    group   => 'wheel',
    mode    => '0644',
    owner   => 'root',
  }

  exec { 'Add pts/0 as a secure TTY':
    command => "/bin/echo 'pts/0' >> /etc/securetty",
    unless  => "/bin/grep 'pts/0' /etc/securetty",
  }

}
