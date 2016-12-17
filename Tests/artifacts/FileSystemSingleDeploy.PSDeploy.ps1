

Deploy FileSystemDiffTest {
    By FileSystemDiff {
        FromSource "$ENV:BHProjectPath\FileSystemDiffSource\test1.txt"
        To "$ENV:BHProjectPath\Dest"
        WithOptions @{
            SaveDiff = $true
        }
    }
}