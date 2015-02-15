#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

#Debug mode
set -x

usage() {
  printf "Usage: %s: -c <vm_name> <snapshot name>\n" $(basename $0) >&2
  exit 2
}

qemu_img="cloud-qemu-img"
virsh="/usr/bin/virsh"

which $qemu_img >& /dev/null
if [ $? -gt 0 ]
then
   which qemu-img >& /dev/null
   if [ $? -eq 0 ]
   then
       qemu_img="qemu-img"
   fi
fi


create_snapshot() {
  #virsh snapshot-create-as <domain> [<name>] [<description>] [--print-xml] [--no-metadata] [--halt] [--disk-only] [--reuse-external] [--quiesce] [--atomic] [--live] [<memspec>] [[--diskspec] <string>]...
  local vmname=$1
  local snapshotname="$2"
  local failed=0
  $virsh snapshot-create-as $vmname "$snapshotname" --atomic
  if [ $? -gt 0 ]
  then
    failed=1
    printf "***Failed to create snapshot $snapshotname for vm $vmname\n" >&2
  fi
  return $failed
}

destroy_snapshot() {
  #virsh snapshot-delete <domain> [<snapshotname>] [--current] [--children] [--children-only] [--metadata]
  local vmname=$1
  local snapshotname="$2"
  local failed=0
  #cheeck if instance exists
  state=$(virsh domstate $vmname)
  if [ "$state" == "running" ]; then
    $virsh snapshot-delete $vmname "$snapshotname"
    if [ $? -gt 0 ]
    then
      failed=1
      printf "***Failed to destroy snapshot $snapshotname for vm $vmname\n" >&2
    fi
  else
    echo "VM doesn't exist!"
  fi
  return $failed
}

rollback_snapshot() {
  #virsh snapshot-revert <domain> [<snapshotname>] [--current] [--running] [--paused] [--force]
  local vmname=$1
  local snapshotname="$2"
  local failed=0
  $virsh snapshot-revert $vmname $snapshotname
  if [ $? -gt 0 ]
  then
    printf "***Failed to rollback snapshot $snapshotname for $vmname\n" >&2
    failed=1
  fi
  return $failed
}


while getopts 'c:d:r:n:b:p:t:f' OPTION
do
  case $OPTION in
  c)	cflag=1
	vmname="$OPTARG"
	;;
  d)    dflag=1
        vmname="$OPTARG"
        ;;
  r)    rflag=1
        vmname="$OPTARG"
        ;;
  n)	nflag=1
	snapshot="$OPTARG"
	;;
  ?)	usage
	;;
  esac
done


[ -z "${snapshot}" ] && usage

if [ "$cflag" == "1" ]
then
  create_snapshot $vmname "$snapshot"
  exit $?
elif [ "$dflag" == "1" ]
then
  destroy_snapshot $vmname "$snapshot"
  exit $?
elif [ "$rflag" == "1" ]
then
  rollback_snapshot $vmname "$snapshot"
  exit $?
fi

exit 0
