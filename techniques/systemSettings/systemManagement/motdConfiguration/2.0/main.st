#####################################################################################
# Copyright 2011-2013 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

##############################################################
# Sets the MOTD according to the value given in the Directive.
##############################################################

bundle agent rudder_motd_configuration(class_prefix, service_name, trackingkey, params)
{
  vars:
      "rudder_motd_payload"     string => "${${params}[payload]}";
      "rudder_motd_empty"       string => "${${params}[file_empty]}";

    debian::
      "rudder_motd_file"         slist => { "/etc/motd", "/etc/motd.tail" };

    !debian::
      "rudder_motd_file"         slist => { "/etc/motd" };

    aix::
      "rudder_motd_group"       string => "bin";
    !aix::
      "rudder_motd_group"       string => "root";

  classes:
      "rudder_motd_absent"         not => fileexists("/etc/motd");

  files:
    # Set every MOTD file to the wanted value
    !windows::
      "${rudder_motd_file}"
        create        => "true",
        edit_defaults => rudder_empty_select("${rudder_motd_empty}"),
        perms         => mog("644", "root", "${rudder_motd_group}"),
        edit_line     => insert_lines("${rudder_motd_payload}"),
        classes       => rudder_common_classes("${class_prefix}_file_edition");

  methods:
    # Here, we will define reports for elements which only have a local visibility (like the MOTD file presence detection).
    !windows.rudder_motd_absent::
      "any"
        usebundle  => rudder_common_report("${service_name}", "log_repaired", "${trackingkey}", "MOTD Configuration", "None", "The ${service_name} file was absent, it will be created");

}

# The reporting is made on separate bundles to abstract the complexity
# inherent to the normal ordering.
bundle agent rudder_motd_configuration_reporting(class_prefix, service_name, trackingkey)
{
  methods:
      "any" usebundle => rudder_common_reports_generic("${service_name}", "${class_prefix}_file_edition", "${trackingkey}", "MOTD Configuration", "None", "The ${service_name} file");
    windows::
      "any"
        usebundle  => rudder_common_report("${service_name}", "result_error", "${trackingkey}", "MOTD Configuration", "None", "This is a Windows machine. This Technique currently incompatible with it");
}
