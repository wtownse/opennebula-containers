#!/bin/bash
if [ -f /etc/one/onegate-server.conf ]; then
rm /etc/one/onegate-server.conf
fi

cat >/etc/one/onegate-server.conf << EOL
# -------------------------------------------------------------------------- #
# Copyright 2002-2020, OpenNebula Project, OpenNebula Systems                #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

################################################################################
# Server Configuration
################################################################################

# OpenNebula sever contact information
#
:one_xmlrpc: http://localhost:2633/RPC2

# Server Configuration
#
:host: 127.0.0.1
:port: 5030

# SSL proxy URL that serves the API (set if is being used)
#:ssl_server: https://service.endpoint.fqdn:port/

################################################################################
# Log
################################################################################

# Log debug level
#   0 = ERROR, 1 = WARNING, 2 = INFO, 3 = DEBUG
#
:debug_level: 3

################################################################################
# Auth
################################################################################

# Authentication driver for incomming requests
#   onegate, based on token provided in the context
#
:auth: onegate

# Authentication driver to communicate with OpenNebula core
#   cipher, for symmetric cipher encryption of tokens
#   x509, for x509 certificate encryption of tokens
#
:core_auth: cipher


################################################################################
# OneFlow Endpoint
################################################################################

:oneflow_server: http://localhost:2474


################################################################################
# Permissions
################################################################################

:permissions:
  :vm:
    :show: true
    :show_by_id: true
    :update: true
    :update_by_id: true
    :action_by_id: true
  :service:
    :show: true
    :change_cardinality: true

# Attrs that cannot be modified when updating a VM template
:restricted_attrs:
  - SCHED_REQUIREMENTS
  - SERVICE_ID
  - ROLE_NAME

# Actions that cannot be performed on a VM
:restricted_actions:
  #- deploy
  #- hold
  #- livemigrate
  #- migrate
  #- resume
  #- release
  #- stop
  #- suspend
  #- saveas
  #- snapshot_create
  #- snapshot_revert
  #- snapshot_delete
  #- terminate
  #- reboot
  #- poweroff
  #- chown
  #- chmod
  #- resize
  #- attachdisk
  #- detachdisk
  #- attachnic
  #- detachnic
  #- rename
  #- undeploy
  #- resched
  #- unresched
  #- recover
EOL

#echo "serveradmin:${ONEPASSWORD}" >> /var/lib/one/.one/onegate_auth
