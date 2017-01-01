

Deploy FileSystemDiffTest {
    By FileSystemDiff {
        FromSource "$ENV:BHProjectPath\Tests\Types\FileSystemDiffSource\test1.txt"
        To "$ENV:BHProjectPath\Dest"
        WithOptions @{
            SaveDiff = $true
        }
    }
}