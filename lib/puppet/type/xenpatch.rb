#!/usr/bin/env ruby
#____________________________________________________________________
# File: xenpatch.rb
#____________________________________________________________________
#
# Author:  <sashby@dfi.ch>
# Created: 2015-05-26 09:32:35+0200
# Revision: $Id$
# Description: The xenpatch type definition.
#
# Copyright (C) 2015
#
#
#--------------------------------------------------------------------

Puppet::Type.newtype(:xenpatch) do
  # uuid ( RO)                    : f359f49e-0c5a-4e38-8da0-9f550dab5f64
  #               name-label ( RO): XS62ESP1025
  #         name-description ( RO): Public Availability: Security fixes for Xen Device Model
  #                     size ( RO): 32457451
  #                    hosts (SRO): 2f5bd4c7-6f09-4cb1-a75c-9c5d06392b31
  #     after-apply-guidance (SRO): restartHost
  #
  @doc = %q{Creates a patch for Citrix XenServer, managed using xe.

    Example:

      xenpatch { 'XS62ESP1025':
        ensure => installed,
        source => '/root/XS62ESP1025.xsupdate',
      }
  }

  feature :installable, "The provider can install Xen patches.", :methods => [:install]
  feature :upgradeable, "The provider can upgrade Xen patches.", :methods => [:upgrade]

  feature :auth_params, "The provider accepts parameters to be passed to the xe command for auth purposes."

  ensurable do
    desc "What state the patch should be in. Default is 'installed'." # Here perhaps we should also have 'applied' for slaves.

    newvalue(:present, :event => :patch_installed) do
      provider.install
    end

    newvalue(:absent, :event => :patch_removed) do
      provider.uninstall
    end

    newvalue(:latest, :required_features => :upgradeable) do
      current = self.retrieve
      begin
        provider.update
      rescue => detail
        self.fail Puppet::Error, "Could not update: #{detail}", detail
      end

      if current == :absent
        :patch_installed
      else
        :patch_changed
      end
    end

    defaultto :installed

    # Alias the 'present' value.
    aliasvalue(:installed, :present)

  end

  # A simple bypass mechanism:
  newproperty(:enable) do
    newvalues(:true, :false)
  end

  newparam(:name, :namevar => true) do
    desc "The Xen patch name.  This is the name that Citrix assigns the patch. It is also the version."

    validate do |value|
      if !value.is_a?(String)
        raise ArgumentError, "Name must be a String not #{value.class}"
      end
      unless value =~ /^XS\w+/
        raise ArgumentError, "%s is not a valid patch name" % value
      end
    end
  end

  newparam(:auth_params, :required_features => :auth_params) do
    desc "A hash of auth params to be handled by the provider when installing a patch using `xe`."
  end

  newparam(:source) do
    desc "Where to find the patch file. This patch file is the raw Zip file downloaded from Citrix.
        The provider is unable to download from Citrix support site directly.

        The value of `source` is a path to a local files stored on the target system.

        You can use a `file` resource if you need to manually copy package files
        to the target system."

    validate do |value|
      unless value =~ /XS.*xsupdate/
        raise ArgumentError, "%s is not a valid patch file name (should have .xsupdate suffix)." % value
      end
      # Further validation:
      provider.validate_source(value)
    end
  end

  newparam(:uuid) do
    desc "The UUID of the uploaded patch as returned by `xe patch-upload`."
  end

  newparam(:label) do
    desc "The name-label set by the patch manager. Same as name."
  end

  newparam(:description) do
    desc "A description of the patch and what it is for. "
  end

  newparam(:size) do
    desc "The size of the patch file in bytes."
  end

  newparam(:guidance) do
    desc "A helpful hint as to action required by the system after the patch is installed."
  end

end
