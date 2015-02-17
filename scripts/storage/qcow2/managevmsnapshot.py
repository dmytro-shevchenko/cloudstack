#!/usr/bin/env python

import argparse, sys, libvirt
from string import Template

snapshot_xml_template = """
<domainsnapshot>
  <name>$name</name>
  <description>$description</description>
  <state>$state</state>
  <memory snapshot='internal'/>
  <disks>
  </disks>
</domainsnapshot>
"""


class Libvirt():
    def __init__(self):
        self.__connection = libvirt.open('qemu:///system')
        if not self.__connection:
            print 'Failed to open connection to the hypervisor'
            sys.exit(1)

    def __get_vm(self, vmname):
        try:
            return self.__connection.lookupByName(vmname)
        #except libvirt.libvirtError as error:
        #    pass
        except libvirt.libvirtError as error:
            print('Failed to get VM: ' + error.message)
            sys.exit(1)

    def __form_snapshot_XML(self, vm):
        values = {'vmname': '', 'vmid': 0}
        src = Template(snapshot_xml_template)
        result = src.substitute(values)
        return result

    def create_snapshot(self, vmname, snapshotname, description):
        vm = self.__get_vm(vmname)
        result = vm.snapshotCreateXML(self.__form_snapshot_XML(vm), libvirt.VIR_DOMAIN_SNAPSHOT_CREATE_ATOMIC)
        return [True, 'Snapshot successfully created for {0}.'.format(vmname)]

    def get_snapshot_list(self, vmname):
        try:
            vm = self.__get_vm(vmname)
            return vm.snapshotListNames()
        except libvirt.libvirtError as error:
            print('Failed to get VM {0}'.format(str(error)))
            return None



def parse_arguments():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers()
    create = subparsers.add_parser('create', help='Create new snapshot')
    create.add_argument('vmname', metavar='<VM_name>', help='VM name')
    create.add_argument('snapshot', metavar='<snapshot_name>', help='Snapshot name')
    create.set_defaults(create=True)
    destroy = subparsers.add_parser('destroy', help='Destroy snapshot')
    destroy.add_argument('vmname', metavar='<vm_name>', help='VM name')
    destroy.set_defaults(destroy=True)
    revert = subparsers.add_parser('revert', help='Revert snapshot')
    revert.add_argument('vmname', metavar='<vm_name>', help='VM name')
    revert.set_defaults(revert=True)
    list = subparsers.add_parser('list', help='List snapshots')
    list.add_argument('vmname', metavar='<vm_name>', help='VM name')
    list.set_defaults(list=True)
    return parser.parse_args()


def create_snapshot(vmname, snapshot):
    virt = Libvirt()
    result = virt.create_snapshot(vmname, snapshot, '')
    print(result[1])
    if result[0]:
        sys.exit(0)
    else:
        sys.exit(1)



args = parse_arguments()
if hasattr(args, 'create'):
    create_snapshot(args.vmname, args.snapshot)
elif hasattr(args, 'destroy'):
    pass
elif hasattr(args, 'revert'):
    pass
elif hasattr(args, 'list'):
    snapshots = Libvirt().get_snapshot_list(args.vmname)
    print('snapshots ' + snapshots)
else:
    print('No valid command found!')
    sys.exit(1)



