function Get-Hash { 
    <#
        .SYNOPSIS
            Calculates the hash on a given file based on the seleced hash algorithm.

        .DESCRIPTION
            Calculates the hash on a given file based on the seleced hash algorithm. Multiple hashing 
            algorithms can be used with this command.

        .PARAMETER Path
            File or files that will be scanned for hashes.

        .PARAMETER Algorithm
            The type of algorithm that will be used to determine the hash of a file or files.
            Default hash algorithm used is SHA256. More then 1 algorithm type can be used.
            
            Available hash algorithms:

            MD5
            SHA1
            SHA256 (Default)
            SHA384
            SHA512
            RIPEM160

        .NOTES
            Name: Get-FileHash
            Author: Boe Prox
            Created: 18 March 2013
            Modified: 28 Jan 2014
                1.1 - Fixed bug with incorrect hash when using multiple algorithms

        .OUTPUTS
            System.IO.FileInfo.Hash

        .EXAMPLE
            Get-Hash -Path Test2.txt
            Path                             SHA256
            ----                             ------
            C:\users\prox\desktop\TEST2.txt 5f8c58306e46b23ef45889494e991d6fc9244e5d78bc093f1712b0ce671acc15      
            
            Description
            -----------
            Displays the SHA256 hash for the text file.   

        .EXAMPLE
            Get-Hash -Path .\TEST2.txt -Algorithm MD5,SHA256,RIPEMD160 | Format-List
            Path      : C:\users\prox\desktop\TEST2.txt
            MD5       : cb8e60205f5e8cae268af2b47a8e5a13
            SHA256    : 5f8c58306e46b23ef45889494e991d6fc9244e5d78bc093f1712b0ce671acc15
            RIPEMD160 : e64d1fa7b058e607319133b2aa4f69352a3fcbc3

            Description
            -----------
            Displays MD5,SHA256 and RIPEMD160 hashes for the text file.

        .EXAMPLE
            Get-ChildItem -Filter *.exe | Get-Hash -Algorithm MD5
            Path                               MD5
            ----                               ---
            C:\users\prox\desktop\handle.exe  50c128c5b28237b3a01afbdf0e546245
            C:\users\prox\desktop\PortQry.exe c6ac67f4076ca431acc575912c194245
            C:\users\prox\desktop\procexp.exe b4caa7f3d726120e1b835d52fe358d3f
            C:\users\prox\desktop\Procmon.exe 9c85f494132cc6027762d8ddf1dd5a12
            C:\users\prox\desktop\PsExec.exe  aeee996fd3484f28e5cd85fe26b6bdcd
            C:\users\prox\desktop\pskill.exe  b5891462c9ca5bddfe63d3bae3c14e0b
            C:\users\prox\desktop\Tcpview.exe 485bc6763729511dcfd52ccb008f5c59

            Description
            -----------
            Uses pipeline input from Get-ChildItem to get MD5 hashes of executables.

    #>
    [CmdletBinding(DefaultParameterSetName='File')]
    Param(
       [Parameter( ParameterSetName = 'File',
                   Position=0,
                   Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$True)]
       [Alias("PSPath","FullName")]
       [string[]]$Path,

       [Parameter( ParameterSetName = 'String',
                   Position=0,
                   Mandatory=$true)]
       [string[]]$String,

       [Parameter(Position=1)]
       [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
       [string[]]$Algorithm = "SHA256"
    )
    Process {

        if($PSCmdlet.ParameterSetName -eq 'File')
        {
            $Items = $Path
        }
        elseif($PSCmdlet.ParameterSetName -eq 'String')
        {
            $Items = $String
        }

        ForEach ($item in $Items) {
            
            if($PSCmdlet.ParameterSetName -eq 'File')
            {

                $item = (Resolve-Path $item).ProviderPath
                If (-Not ([uri]$item).IsAbsoluteUri) {
                    Write-Verbose ("{0} is not a full path, using current directory: {1}" -f $item,$pwd)
                    $item = (Join-Path $pwd ($item -replace "\.\\",""))
                }
                If(Test-Path $item -Type Container) {
                   Write-Warning ("Cannot calculate hash for directory: {0}" -f $item)
                   Return
                }
                $object = New-Object PSObject -Property @{ 
                    Path = $item
                }
                #Open the Stream
                $stream = ([IO.StreamReader]$item).BaseStream
            

                foreach($Type in $Algorithm) {                
                
                    [string]$hash = -join ([Security.Cryptography.HashAlgorithm]::Create( $Type ).ComputeHash( $stream ) | 
                        ForEach { "{0:x2}" -f $_ })
                
                    $null = $stream.Seek(0,0)
                
                    #If multiple algorithms are used, then they will be added to existing object                
                    $object = Add-Member -InputObject $Object -MemberType NoteProperty -Name $Type -Value $Hash -PassThru
                }
            }
            elseif($PSCmdlet.ParameterSetName -eq 'String')
            {

                $object = New-Object PSObject -Property @{ 
                    String = $item
                }

                foreach($Type in $Algorithm) {                
                    [string]$hash = -join ([Security.Cryptography.HashAlgorithm]::Create( $Type ).ComputeHash( [System.Text.Encoding]::UTF8.GetBytes($item) ) | 
                        ForEach { "{0:x2}" -f $_ })
                    
                    #If multiple algorithms are used, then they will be added to existing object                
                    $object = Add-Member -InputObject $Object -MemberType NoteProperty -Name $Type -Value $Hash -PassThru
                }
            }

            $object.pstypenames.insert(0,'System.IO.FileInfo.Hash')
            
            #Output an object with the hash, algorithm and path
            Write-Output $object

            if($PSCmdlet.ParameterSetName -eq 'File')
            {
                #Close the stream
                $stream.Close()
                $stream.Dispose()
            }
        }
    }
}