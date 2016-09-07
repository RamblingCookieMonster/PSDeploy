OVF or OVA are a standard to package virtual machines. vSphereOVF will allow you to deploy an OVF/OVA into a VMware vSPhere infrastructure.

# Prerequisites

Before deploying you'll need to:
- Install VMware PowerCli 
- Connect to a vCenter server or an ESXi server with the command `Connect-VIServer`

# Simple Example

Here is an example deployment config:

```Powershell
Deploy 'MyOVF' {
    By vSphereOVF {
        FromSource 'C:\MyOVF.ovf'
        To 'esxi.example.com'
        Tagged 'Prod'
        WithOptions @{
            Name = 'VM01'
            Datastore = 'DATASTORE01'
            OvfConfiguration = @{
                'NetworkMapping.VM Network' = 'Production'
            }
            PowerOn = $true
        }
    }
}
```

Let's explain the different parameters:
- `FromSource` specifies the path to the .ovf or .ova file
- `To` specifies the esxi server used as a target
- `Name` specifies the name of the virtual machine
- `Datastore` specifies on wich datastore the VM will be stored. If not provided, the datastore with the largest free space will be selected
- `OvfConfiguration` specifies advanced configurations that will be used to deploy the virtual machine
- `PowerOn` specifies if the virtual machine should be powered on after the deployment

# Real Example

Here is an example to deploy a VMware vCenter Virtual Appliance (VCSA). More specific informations about the automated deployment of a VCSA can be found [here](http://www.virtuallyghetto.com/2015/02/ultimate-automation-guide-to-deploying-vcsa-6-0-part-1-embedded-node.html)  

```Powershell
Deploy 'VCSA' {
    By vSphereOVF {
        FromSource 'D:\VMware\vSphere\vSphere 6.0\vCenter\VCSA\U2\vmware-vcsa.ova'
        To 'esxi.example.com'
        Tagged 'Prod'
        WithOptions @{
            Name = 'VCENTER' # VM Name
            Datastore = 'SALLE1-DATASTORE02' # Datastore Name
            OvfConfiguration = @{
                'NetworkMapping.Network 1'                = 'Supervision' # vSphere Portgroup Network Mapping
                'DeploymentOption.value'                  = 'tiny' # tiny,small,medium,large,management-tiny,management-small,management-medium,management-large,infrastructure
                'IpAssignment.IpProtocol'                 = 'IPv4' # IP Protocol
                'guestinfo.cis.appliance.net.addr.family' = 'ipv4' # IP Address Family
                'guestinfo.cis.appliance.net.mode'        = 'static' # IP Address Mode
                'guestinfo.cis.appliance.net.addr'        = '192.168.1.2' # IP Address 
                'guestinfo.cis.appliance.net.pnid'        = '192.168.1.2' # IP PNID (same as IP Address if there's no DNS)
                'guestinfo.cis.appliance.net.prefix'      = '24' # IP Network Prefix (CIDR notation)
                'guestinfo.cis.appliance.net.gateway'     = '192.168.1.254' # IP Gateway
                'guestinfo.cis.appliance.net.dns.servers' = '192.168.1.1' # Comma separated list of IP addresses of DNS servers.
                'guestinfo.cis.appliance.ntp.servers'     = '0.pool.ntp.org' # Comma seperated list of hostnames or IP addresses of NTP Servers
                'guestinfo.cis.appliance.root.passwd'     = 'VMware1!' # Root Password
                'guestinfo.cis.appliance.ssh.enabled'     = 'True' # Enable SSH
                'guestinfo.cis.vmdir.domain-name'         = 'vsphere.local' # SSO Domain Name
                'guestinfo.cis.vmdir.site-name'           = 'site01' # SSO Site Name
                'guestinfo.cis.vmdir.password'            = 'VMware1!' # SSO Admin Password
            }
            PowerOn = $true
        }
    }
}
```
