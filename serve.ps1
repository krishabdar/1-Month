param(
    [int]$Port = 8080,
    [string]$Root = "C:\Users\DELL\.gemini\antigravity\scratch\our-anniversary"
)

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
}

try {
    while ($true) {
        $client = $listener.AcceptTcpClient()
        try {
            $stream = $client.GetStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $requestLine = $reader.ReadLine()
            if ($requestLine) {
                $tokens = $requestLine.Split(" ")
                if ($tokens.Count -ge 2) {
                    $urlPath = $tokens[1]
                    if ($urlPath -eq "/" -or $urlPath -eq "") { $urlPath = "/index.html" }
                    if ($urlPath.Contains("?")) { $urlPath = $urlPath.Substring(0, $urlPath.IndexOf("?")) }

                    $cleanRel = $urlPath.TrimStart("/").Replace("/", [System.IO.Path]::DirectorySeparatorChar)
                    $localPath = Join-Path $Root $cleanRel
                    
                    if (Test-Path $localPath -PathType Leaf) {
                        $ext = [System.IO.Path]::GetExtension($localPath).ToLower()
                        $mime = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
                        $bytes = [System.IO.File]::ReadAllBytes($localPath)
                        
                        $header = "HTTP/1.1 200 OK`r`nContent-Type: $mime`r`nContent-Length: $($bytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nConnection: close`r`n`r`n"
                        $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
                        $stream.Write($headerBytes, 0, $headerBytes.Length)
                        $stream.Write($bytes, 0, $bytes.Length)
                    } else {
                        $notFound = "HTTP/1.1 404 Not Found`r`nContent-Length: 9`r`nConnection: close`r`n`r`nNot Found"
                        $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($notFound)
                        $stream.Write($headerBytes, 0, $headerBytes.Length)
                    }
                    $stream.Flush()
                }
            }
        } catch {
        } finally {
            $client.Close()
        }
    }
} finally {
    $listener.Stop()
}
