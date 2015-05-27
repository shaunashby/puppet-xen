#____________________________________________________________________
# File: xen_pool_master.rb
#____________________________________________________________________
#
# Author:  <sashby@dfi.ch>
# Created: 2015-04-16 09:37:28+0200 (Time-stamp: <2015-05-21 11:46:38 sashby>)
# Revision: $Id$
# Description: Facter plugin to return whether host is a Xen pool master.
#
# Copyright (C) 2015
#
#
#--------------------------------------------------------------------

Facter.add('xen_pool_master') do
  confine :operatingsystem => 'XenServer'
  setcode do
    if File.exist? '/etc/xensource/pool.conf'
      xen_pool_master_cmd    = 'cat /etc/xensource/pool.conf'
      xen_pool_master_result = Facter::Core::Execution.exec(xen_pool_master_cmd)
      # Check if master keyword in file:
      xen_pool_master_result == 'master'
    end
  end
end
