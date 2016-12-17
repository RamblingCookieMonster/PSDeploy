

Deploy FileSystemDiffTest {
    By FileSystemDiff {
        FromSource "$ENV:BHProjectPath\Tests\Types\FileSystemDiffSource"
        To "$ENV:BHProjectPath\Dest"
        WithOptions @{
            SaveDiff = $true
        }
    }
}