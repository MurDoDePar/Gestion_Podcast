$json = Get-Content 'version.json' -Raw | ConvertFrom-Json
$version = $json.version
$build = $json.build_number
$pubspecPath = 'podcast_app\pubspec.yaml'
$pubspec = Get-Content $pubspecPath -Raw
$pubspec = $pubspec -replace '(?m)^version: .*', "version: $version+$build"
[IO.File]::WriteAllText($pubspecPath, $pubspec)
