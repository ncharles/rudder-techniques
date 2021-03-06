#####################################################################################
# Copyright 2014 Normation SAS
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

#
# This promise installs and configures nxlog
#
# This program monitors the windows event log and sends every
# Nova related information to a remote syslog, the Rudder main server
# in our case.


bundle agent nxlog_enable
{

  methods:

    windows::

      "any" usebundle => nxlog_install;
      "any" usebundle => nxlog_configure;
&if(NOVA)&
      "any" usebundle => nxlog_launch;
&endif&

    (nxlog_install_repaired|nxlog_configure_repaired|nxlog_service_repaired).!(nxlog_install_error|nxlog_configure_error|nxlog_service_error)::
      "report" usebundle => rudder_common_report("Common", "result_repaired", "&TRACKINGKEY&", "Log system for reports", "None", "NXLog service was not installed, configured and running. Fixed.");

    !nxlog_install_repaired.!nxlog_install_error.nxlog_configure_kept.!nxlog_configure_repaired.!nxlog_configure_error.nxlog_service_kept.!nxlog_service_repaired.!nxlog_service_error::
      "report" usebundle => rudder_common_report("Common", "result_success", "&TRACKINGKEY&", "Log system for reports", "None", "NXLog service already installed, configured and running as expected.");

}

bundle common nxlog_common
{

  vars:
    windows::
      "nxlog_exe" string => "${g.rudder_tools}/nxlog-ce-2.8.1248.msi";
      "nxlog_tpl" string => "${g.rudder_tools}/nxlog.conf";

    use_udp::
      "transport_module"  string => "om_udp";
    use_tcp::
      "transport_module"  string => "om_tcp";

  classes:
    any::
      "use_udp" expression => strcmp("&RUDDER_SYSLOG_PROTOCOL&", "UDP");
      "use_tcp" expression => strcmp("&RUDDER_SYSLOG_PROTOCOL&", "TCP");
}


bundle agent nxlog_install
{

  classes:

    !x86_64::
      "nxlog_ok" expression => fileexists("${sys.winprogdir}\nxlog\nxlog.exe");

    x86_64::
      "nxlog_ok" expression => fileexists("${sys.winprogdir86}\nxlog\nxlog.exe");

  methods:
    nxlog_install_repaired::
      "report" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Log system for reports", "None", "Installed NXLog");
    nxlog_install_failed::
      "report" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Log system for reports", "None", "Failed to install NXLog");

  commands:

    windows.!nxlog_ok::

      "\"${sys.winsysdir}\msiexec.exe\""
        args    => "/q /i  \"${g.rudder_sbin}\nxlog-ce-2.8.1248.msi",
        classes => rudder_common_classes("nxlog_install"),
        comment => "Installing nxlog";
}

bundle agent nxlog_configure
{

  vars:
    !x86_64::
      "nxlog_config_file" string => "${sys.winprogdir}\nxlog\conf\nxlog.conf";
      "install_path"      string => "${sys.winprogdir}";
    x86_64::
      "nxlog_config_file" string => "${sys.winprogdir86}\nxlog\conf\nxlog.conf";
      "install_path"      string => "${sys.winprogdir86}";

    any::
      "transport_module"  string => "";

  files:

      "${nxlog_config_file}"
        create        => "true",
        classes       => rudder_common_classes("nxlog_configure"),
        edit_line     => nxlog_parameters("${server_info.cfserved}", "&SYSLOGPORT&", "${nxlog_common.transport_module}", "${nxlog_common.nxlog_tpl}", "${nxlog_configure.install_path}"),
        edit_defaults => empty_backup;

  methods:
    nxlog_configure_error::
      "report" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Log system for reports", "None", "Failed to configure NXLog");

    nxlog_configure_repaired::
      "report" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Log system for reports", "None", "Update NXLog configuration");

}

&if(NOVA)&
bundle agent nxlog_launch
{

  methods:
    nxlog_service_error::
      "report" usebundle => rudder_common_report("Common", "result_error", "&TRACKINGKEY&", "Log system for reports", "None", "Error while checking or restarting NXLog server");

    nxlog_service_repaired::
      "report" usebundle => rudder_common_report("Common", "log_repaired", "&TRACKINGKEY&", "Log system for reports", "None", "NXLog was restarted");

  services:

    nxlog_configure_repaired::
      "nxlog"
        service_policy => "stop",
        classes        => rudder_common_classes("nxlog_service"),
        comment        => "When the configuration has changed, we need to stop and start the service (restart fails to achieve expected result)";


    any::
      "nxlog"
        service_policy => "start",
        service_method => u_bootstart,
        classes        => rudder_common_classes("nxlog_service");
}
&endif&

# Parameters are used in the template, expanded thanks to the expand_scalars => true
bundle edit_line nxlog_parameters(server, port, transport_module, template, install_path)
{
  insert_lines:

      "${template}"
        insert_type    => "file",
        expand_scalars => "true";

}
