This is a quick example showing a PSGalleryScript deployment:

## Example

Here's the deployment config, My.PSDeploy.ps1:

```PowerShell
Deploy Script {
    By PSGalleryScript {
        FromSource 'Relative\Path\To\This-Script.ps1'
        To PSGallery
        WithOptions @{
            ApiKey = $ENV:NugetApiKey
            Version = $ENV:Version
            Author = "Warren F."
            Description = "A Description for the gallery"
        }
    }
}
```

In this example, we're deploying the script 'This-Script.ps1' using an API key stored in $ENV:NugetApiKey.

The API key might be stored in a [secure variable](https://www.appveyor.com/docs/build-configuration#secure-variables) of some sort for your build system.

## Notes

WARNING: This deployment type will modify the content of your FromSource files, by appending a header with script info required by the PowerShell Gallery.

Notes on how we define the PSScriptInfo header based on your WithOptions parameters and other info:

* If you specify a WithOptions parameter, that takes precedence over an existing publication
* If you do not specify a WithOptions parameter and have previously published this, we query and re-use data from the existing published script
* In a few special cases (required fields), we will generate initial data if you do not include it in WithOptions or have an existing published script:
  * GUID - We create a new GUID
  * VERSION - we set to 1.0.0
  * AUTHOR - We set to Unknown
  * DESCRIPTION - We set to the file name (e.g. if I publish Open-IseFunction.ps1, DESCRIPTION=Open-ISEFunction)

No output is produced from this deployment type.

