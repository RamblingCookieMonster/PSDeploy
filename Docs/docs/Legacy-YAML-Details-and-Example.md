Current plans for YAML:

* No plans to remove this functionality. If you're using it and happy with it, it should continue to work without issue.
* New features will focus on *.PSDeploy.ps1 style deployments.  These may or may not be ported to YAML based deployments.
* Contributions to support these new features in YAML are more than welcome.

### Deployment Configurations: Deployment yaml

These are simple, static yaml files that tell PSDeploy what to deploy.

We use the following attributes:

```
DeploymentName:    Name for a particular deployment.  Must be unique.
DeploymentAuthor:  Optional author for the deployment
DeploymentType:    The type of deployment.  Tells PSDeploy how to deploy (FileSystem, ARM, etc.)
DeploymentOptions: One or more options to pass along to the DeploymentType script
Tags:              One or more tags associated with this deployment
Source:            One or more source items to deploy
Targets:           One or more targets to deploy to
```

A Deployment yaml file will have one or more deployment blocks like this:

```yaml
UniqueDeploymentName:                   # Deployment name
  Author: 'OptionalAuthorName'          # Author name. Optional
  Source:                               # One or more sources to deploy. These are specific to your DeploymentType
    - 'RelativeSourceFolder'
    - 'Subfolder\RelativeSource.File'
    - '\\Absolute\Source$\FolderOrFile'
  Destination:                          # One or more destinations to target for deployment. These are specific to a DeploymentType
    - '\\Some\Target$\Folder'
    - '\\Another\Target$\Folder'
  Tags:                                  # One or more tags for this deployment. Optional
    - 'Prod'
  DeploymentType: Filesystem             # Among others, see Get-PSDeploymentType
  DeploymentOptions:                     # Deployment options to pass as parameters to DeploymentType script. Optional.
    Mirror: True                         # In this example, Filesystem DeploymentType can mirror folders
```