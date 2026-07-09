$port = 8888
$folder = Split-Path -Parent $MyInvocation.MyCommand.Path
$dataFile = Join-Path $folder "data.json"
if (-not (Test-Path $dataFile)) { "[]" | Out-File $dataFile -Encoding UTF8 }
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
$mimeTypes = @{".html"="text/html; charset=utf-8";".css"="text/css; charset=utf-8";".js"="application/javascript; charset=utf-8";".json"="application/json; charset=utf-8"}
while ($listener.IsListening) {
    $ctx = $listener.GetContext(); $req = $ctx.Request; $res = $ctx.Response; $path = $req.Url.AbsolutePath
    try {
        if ($path -eq "/api/load") {
            $json = Get-Content $dataFile -Encoding UTF8 -Raw
            $bytes = [Text.Encoding]::UTF8.GetBytes($json)
            $res.ContentType = "application/json; charset=utf-8"; $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        } elseif ($path -eq "/api/save" -and $req.HttpMethod -eq "POST") {
            $reader = New-Object System.IO.StreamReader($req.InputStream, [Text.Encoding]::UTF8)
            $body = $reader.ReadToEnd(); $reader.Close()
            $body | Out-File $dataFile -Encoding UTF8 -NoNewline
            $msg = [Text.Encoding]::UTF8.GetBytes('{"ok":true}')
            $res.ContentType = "application/json; charset=utf-8"; $res.ContentLength64 = $msg.Length
            $res.OutputStream.Write($msg, 0, $msg.Length)
        } else {
            if ($path -eq "/") { $path = "/index.html" }
            $filePath = Join-Path $folder $path.TrimStart("/")
            if (Test-Path $filePath -PathType Leaf) {
                $ext = [IO.Path]::GetExtension($filePath); $mime = $mimeTypes[$ext]
                if (-not $mime) { $mime = "application/octet-stream" }
                $bytes = [IO.File]::ReadAllBytes($filePath)
                $res.ContentType = $mime; $res.ContentLength64 = $bytes.Length
                $res.OutputStream.Write($bytes, 0, $bytes.Length)
            } else { $res.StatusCode = 404 }
        }
    } catch { $res.StatusCode = 500 }
    $res.Close()
}
