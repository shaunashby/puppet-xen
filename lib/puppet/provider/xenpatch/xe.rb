#!/usr/bin/env ruby
#____________________________________________________________________
# File: xe.rb
#____________________________________________________________________
#
# Author:  <sashby@dfi.ch>
# Created: 2015-05-26 09:30:26+0200
# Revision: $Id$
# Description: Provider for xenpatch type.
#
# Copyright (C) 2015
#
#
#--------------------------------------------------------------------
#
#
# uuid ( RO)                    : f359f49e-0c5a-4e38-8da0-9f550dab5f64
#               name-label ( RO): XS62ESP1025
#         name-description ( RO): Public Availability: Security fixes for Xen Device Model
#                     size ( RO): 32457451
#                    hosts (SRO): 2f5bd4c7-6f09-4cb1-a75c-9c5d06392b31
#     after-apply-guidance (SRO): restartHost
#
Puppet::Type.type(:xenpatch).provide(:xe) do
  desc "XenPatch provider, using the xe executable. Only for use on XenServer installs."

  confine    :operatingsystem => 'XenServer'
  defaultfor :operatingsystem => 'XenServer'

  has_command(:xe, '/opt/xensource/bin/xe')

  has_feature :installable
  has_feature :uninstallable
  has_feature :upgradeable
  has_feature :versionable

  has_feature :auth_params

  # Prefetch the patch list:
  def self.prefetch(patches)
    instances.each do |prov|
      Puppet.debug(prov.inspect)
    end
  end

  def self.instances
    patches = []
    model_hash = {}

    uuid_regex = /^uuid.*?: ([a-z0-9\-]*)$/
    name_label_regex = /\s+name-label.*?: (.*?)$/
    name_description_regex = /\s+name-description.*?: (.*?)$/
    size_regex = /\s+size.*?: (\d+)/
    after_apply_guidance_regex = /\s+after-apply-guidance.*?: (.*?)$/

    xe('patch-list').each_line do |line|
      if m = uuid_regex.match(line)
        if model_hash.empty?
          # A new entry:
          model_hash[:uuid] = m[1]
        else
          # Reset for the next entry:
          patches << new(model_hash)
          model_hash={ :uuid => m[1]}
        end
      elsif m = name_label_regex.match(line)
        model_hash[:name_label] = m[1]
        # Also add name:
        model_hash[:name] = m[1]
      elsif m = name_description_regex.match(line)
        model_hash[:name_description] = m[1]
      elsif m = size_regex.match(line)
        model_hash[:size] = m[1]
      elsif m = after_apply_guidance_regex.match(line)
        model_hash[:after_apply_guidance] = m[1]
      end
    end
    # Save the last entry:
    patches << new(model_hash)
    Puppet.debug("XE patches pre-fetched. #{patches.length} installed patches found.")
    patches
  end

  def exists?
  end

  def uploaded?
    # Check to see if the patch file has been uploaded:
  end

  def install
    # For uploading a patch file and for patch-pool-apply, we need the root password.
    # Get this from :auth_params
    if resource[:auth_params]
      Puppet.debug("Got auth_params => #{resource[:auth_params].inspect}")
    else
      fail("xenpatch must have auth_params to connect to pool master.")
    end

    should = @resource.should(:ensure)
    if [:latest, :installed, :present].include?(should)
      patch_uuid = xe("patch-upload file-name=",@resource[:source])
      Puppet.debug("XE: Uploaded patch; UUID = #{patch-uuid}")
    end
  end

  def uninstall # Impossible to remove patches
    nil
  end

  def upload_patch

  end

  # Clear out the cached values.
  def flush
    @property_hash.clear
  end

  def validate_source(value)
    # Check that the path to the source Zip file is absolute and valid:
    fail("xenpatch must have a source parameter.") if value.nil?
    if !absolute_path?(value)
      fail("xenpatch source parameter must be an absolute path.")
    end
    true
  end

  def update # Could use an alias here
    install
  end

  def auth_params
    join_options(resource[:auth_params])
  end

end
