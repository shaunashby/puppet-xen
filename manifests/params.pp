class xen::params {
  # Only use from XenServer:
  case $::operatingsystem {
    'XenServer': {
      $patch_enable = false
      $patch_list   = []
    }
    default: {
      fail("${module_name} is only supported on XenServer.")
    }
  }
}
