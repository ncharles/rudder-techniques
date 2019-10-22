#####################################################################################
# Copyright 2018 Normation SAS
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

bundle agent monitoring_hook_pre
{
  methods:
    "reporting" usebundle => disable_reporting;
    "deletion" usebundle => file_absent("/var/rudder/tmp/rudder_monitoring.csv");
    "reporting" usebundle => enable_reporting;
}

bundle agent monitoring_hook_post
{
  classes:
    "csv_exists" expression => fileexists("/var/rudder/tmp/rudder_monitoring.csv");

  methods:
    "reporting" usebundle => disable_reporting;
    "reporting" usebundle => _method_reporting_context("Monitoring", "None");
    
    csv_exists::
    "share file" usebundle => sharedfile_to_node("root", "rudder_monitoring.csv", "/var/rudder/tmp/rudder_monitoring.csv", "1d");
    
    any::
    "reporting" usebundle => enable_reporting;
    
    csv_exists::
    "reporting" usebundle => rudder_common_reports_generic("Common", "sharedfile_to_node_rudder_monitoring_csv", "&TRACKINGKEY&", "Monitoring", "None", "Share Rudder monitoring information with the server");

    !csv_exists::
    "reporting" usebundle => rudder_common_report("Common", "result_na", "&TRACKINGKEY&", "Monitoring", "None", "No Rudder monitoring information to share with the server");
}