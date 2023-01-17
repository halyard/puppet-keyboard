# @summary Configure keyboard gadget
#
# @param kvmtoggle_secret sets the shared key to authenticate kvmtoggle requests
# @param kvmtoggle_version is the version of the kvmtoggle binary to download
class keyboard (
  String $kvmtoggle_secret,
  String $kvmtoggle_version = 'v0.0.1',
) {
  file { '/boot/config.txt':
    ensure => file,
    source => 'puppet:///modules/keyboard/config.txt',
  }

  file { '/etc/modules-load.d/keyboard':
    ensure  => file,
    content => 'dwc2',
  }

  file { '/usr/local/bin/hid_gadget_setup.sh':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/keyboard/hid_gadget_setup.sh',
  }

  -> file { '/etc/systemd/system/hid-setup.service':
    ensure => file,
    source => 'puppet:///modules/keyboard/hid-setup.service',
  }

  ~> service { 'hid-setup':
    ensure => running,
    enable => true,
  }

  $binfile = '/usr/local/bin/kvmtoggle'
  $url = "https://github.com/akerl/kvmtoggle/releases/download/${kvmtoggle_version}/kvmtoggle_linux_arm64"

  exec { 'download kvmtoggle':
    command => "/usr/bin/curl -sLo '${binfile}' '${url}' && chmod a+x '${binfile}'",
    unless  => "/usr/bin/test -f ${binfile} && ${binfile} version | grep '${kvmtoggle_version}'",
  }

  -> file { '/etc/systemd/system/kvmtoggle.service':
    ensure  => file,
    content => template('keyboard/kvmtoggle.service.erb'),
  }

  ~> service { 'kvmtoggle':
    ensure => running,
    enable => true,
  }

  firewall { "100 allow inbound 8080 for kvmtoggle":
    dport  => 8080,
    proto  => 'tcp',
    action => 'accept',
  }
}
