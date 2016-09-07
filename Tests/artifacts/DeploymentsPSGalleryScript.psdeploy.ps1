Deploy TestScript {
    By PSGalleryScript {
        FromSource '\Scripts\Open-IseFunction.ps1'
        To 'PSGallery'
        Tagged Testing
        WithOptions @{
            ApiKey = '0c3e374b-49a3-4b05-a597-fd45773a4fb6'
        }
    }
}