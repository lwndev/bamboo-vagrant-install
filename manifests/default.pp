define append_if_no_such_line($file, $line, $refreshonly = 'false') {
   exec { "/bin/echo '$line' >> '$file'":
      unless      => "/bin/grep -Fxqe '$line' '$file'",
      path        => "/bin",
      refreshonly => $refreshonly,
   }
}

class must-have {
  include apt
  include postgresql::server

  apt::ppa { "ppa:webupd8team/java": }

  $bamboo_version = "4.4.5"
  $bamboo_install = "/vagrant/atlassian-bamboo-${bamboo_version}"
  $bamboo_home = "/vagrant/bamboo-home"
  

  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  exec { 'apt-get update 2':
    command => '/usr/bin/apt-get update',
    require => [ Apt::Ppa["ppa:webupd8team/java"], Package["git-core"] ],
  }

  package { ["vim",
             "curl",
             "git-core",
             "bash",
             "ant",
             "maven",
             "phantomjs",
             "apache2"]:
    ensure => present,
    require => Exec["apt-get update"],
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  postgresql::db { 'bamboo':
    user     => 'bamboo',
    password => 'bamboo',
    require  => Exec['create_bamboo_home'],
  }

  package { ["oracle-java7-installer"]:
    ensure => present,
    require => Exec["apt-get update 2"],
  }

  file { "bamboo.properties":
    path => "/vagrant/atlassian-bamboo-${bamboo_version}/webapp/WEB-INF/classes/bamboo-init.properties",
    content => "bamboo.home=${bamboo_home}",
    require => Exec["create_bamboo_home"],
  }

  file { "httpd.conf":
    path => "/etc/apache2/httpd.conf",
    content => template('bamboo/bamboo.httpd.conf'),
    require => Package["apache2"],
  }

  file { "bamboo.wrapper.conf":
    path => "${bamboo_install}/conf/wrapper.conf",
    content => template('bamboo/bamboo.wrapper.conf'),
    require => Exec["download_bamboo"],
  }

  file { "bamboo.jetty.xml":
    path => "${bamboo_install}/webapp/WEB-INF/classes/jetty.xml",
    content => template('bamboo/bamboo.jetty.xml'),
    require => File["bamboo.wrapper.conf"],
  }

  exec { "/usr/sbin/a2enmod proxy":
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/proxy.load",
    notify => Exec["reload-apache2"],
    require => File["httpd.conf"],
  }

  exec { "/usr/sbin/a2enmod proxy_http":
    unless => "/bin/readlink -e /etc/apache2/mods-enabled/proxy_http.load",
    notify => Exec["reload-apache2"],
    require => File["httpd.conf"],
  }

  exec {
    "accept_license":
    command => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
    path    => "/usr/bin/:/bin/",
    require => Package["curl"],
    before => Package["oracle-java7-installer"],
    logoutput => true,
  }

  exec {
    "download_bamboo":
    command => "sudo curl -L http://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${bamboo_version}.tar.gz | sudo tar zx",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
    creates => "/vagrant/atlassian-bamboo-${bamboo_version}",
  }

  exec {
    "create_bamboo_home":
    command => "sudo mkdir -p ${bamboo_home}",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["download_bamboo"],
    logoutput => true,
    creates => "${bamboo_home}",
  }

  exec {
    "start_bamboo_in_background":
    environment => "BAMBOO_HOME=${bamboo_home}",
    command => "sudo /vagrant/atlassian-bamboo-${bamboo_version}/bamboo.sh start &",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => [ Package["oracle-java7-installer"],
                 Exec["accept_license"],
                 Exec["download_bamboo"],
                 Exec["create_bamboo_home"] ],
    logoutput => true,
  }

  append_if_no_such_line { motd:
    file => "/etc/motd",
    line => "Run Bamboo with: BAMBOO_HOME=${bamboo_home} /vagrant/atlassian-bamboo-${bamboo_version}/bamboo.sh",
    require => Exec["start_bamboo_in_background"],
  }

  # Notify this when apache needs a reload. This is only needed when
   # sites are added or removed, since a full restart then would be
   # a waste of time. When the module-config changes, a force-reload is
   # needed.
   exec { "reload-apache2":
      command => "/etc/init.d/apache2 reload",
      refreshonly => true,
   }

   exec { "force-reload-apache2":
      command => "/etc/init.d/apache2 force-reload",
      refreshonly => true,
   }

   # We want to make sure that Apache2 is running.
   service { "apache2":
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      require => Package["apache2"],
   }

}

include must-have
