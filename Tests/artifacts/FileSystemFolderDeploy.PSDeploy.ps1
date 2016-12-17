

Deploy FileSystemDiffTest {
    By FileSystemDiff {
        FromSource "$ENV:BHProjectPath\FileSystemDiffSource"
        To "$ENV:BHProjectPath\Dest"
        WithOptions @{
            SaveDiff = $true
        }
    }
}