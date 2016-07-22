Deploy Test {
    By vSphereOVF {
        FromSource 'D:\MyOVF.ovf' # OVF/OVA Source
        To 'esxi.example.com' # ESXi server
        Tagged 'Prod'
        WithOptions @{
            Name = 'MyVM' # VM Name
            Datastore = 'DATASTORE01' # Datastore Name
            OvfConfiguration = @{
                'NetworkMapping.VM Network' = 'Supervision' # vSphere Portgroup Network Mapping
            }
        }
    }
}

