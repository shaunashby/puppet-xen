define xen::upload_patch {

  file { "/root/patch/${name}.zip":
    ensure => present,
    source => "puppet:///modules/xen/root/patch/${name}.zip",
  }

  exec { "Unpack ${name}.zip":
    command => "/usr/bin/unzip /root/patch/${name}.zip -d /root/patch",
    unless  => "/usr/bin/test -f /root/patch/${name}.xsupdate",
    require => File["/root/patch/${name}.zip"],
  }

  file { "/root/patch/${name}.xsupdate":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    require => Exec["Unpack ${name}.zip"],
  }

}
