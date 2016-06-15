PlatyPS allows you to write External PowerShell Help using Markdown.

You can learn more at the [Github Page](https://github.com/PowerShell/platyPS).

# Example 1

### MyModule.PSDeploy.ps1

Here's an example Deployment config:

```PowerShell
Deploy MyModule {
    By PlatyPS {
        FromSource 'docs'
        To "MyModule\en-US"
        Tagged Help, Module
        WithOptions @{
            Force = $true
        }
    }
}
```

This deployment takes the markdown files from the `docs` folder and and converts them to an external MAML help file in the `MyModule\en-US` directory. Force will overwrite the destination if it exists.

# Example 2

### MyModuleUnicode.PSDeploy.ps1

This example shows using Unicode as the Encoding.

```PowerShell
Deploy MyModuleUnicode {
    By PlatyPS {
        FromSource 'docs'
        To "MyModule\en-US"
        Tagged Help, Module
        WithOptions @{
            Force = $true
            Encoding = ([System.Text.Encoding]::Unicode)
        }
    }
}
```

This deployment takes the markdown files from the `docs` folder and and converts them to an external MAML help file in the `MyModule\en-US` directory using the command `New-ExternalHelp`.

The option `Encoding` is used in this example and sets the Help encoding. There are some instances where a different encoding is needed. This normally shouldn't be needed.