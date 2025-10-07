# カレントディレクトリ以下のすべてのディレクトリを探索
Get-ChildItem -Recurse -File | Where-Object {
    $_.Name -eq "dub.json" -or $_.Name -eq "dub.sdl"
} | ForEach-Object {
    $projectDir = $_.DirectoryName
    Write-Host "🔧 Building in: $projectDir"
    Push-Location $projectDir
    try {
        dub build
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Build succeeded in: $projectDir"
        } else {
            Write-Host "❌ Build failed in: $projectDir"
        }
    } catch {
        Write-Host "⚠️ Error in: $projectDir - $_"
    }
    Pop-Location
}
