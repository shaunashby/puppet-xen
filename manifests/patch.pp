class xen::patch(
  $patch_enable = $xen::params::patch_enable,
  $patch_list   = $xen::params::patch_list,
) inherits xen::params {

  if !(is_array($patch_list)) {
    fail("${module_name}: patch_list variable should be an array.")
  }

  if $patch_enable == true {

    case "${::xen_pool_master}" {
      'true': {
        notify { "XenPatch: ${::fqdn} is Xen pool MASTER.": }

        file { '/root/patch':
          ensure => directory,
        }

        upload_patch { $patch_list: }
      }
      'false': {
        # Actions required for slaves:
      }
    }
  }
}
