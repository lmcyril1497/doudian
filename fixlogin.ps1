$c=[System.IO.File]::ReadAllText("D:\demo\index.html",[System.Text.Encoding]::UTF8)

# Replace login CSS
$oldCSS=@'
/* ── Login Wall ── */
.login-wall { position:fixed; inset:0; z-index:9999; background:#f5f5f7; display:flex; align-items:center; justify-content:center; padding:20px; }
.lw-card { width:340px; max-width:100%; background:#fff; border-radius:18px; box-shadow:0 4px 24px rgba(0,0,0,.06); padding:36px 32px 28px; display:flex; flex-direction:column; }
.lw-brand { text-align:center; font-size:20px; font-weight:600; color:#1d1d1f; margin-bottom:28px; }
.lw-fields { display:flex; flex-direction:column; gap:14px; margin-bottom:18px; }
.lw-field input { width:100%; height:48px; padding:0 14px; border:2px solid #e4e4e7; border-radius:10px; font-size:15px; font-family:inherit; color:#1d1d1f; outline:none; transition:border-color .15s; }
.lw-field input:focus { border-color:#667eea; }
.lw-field input::placeholder { color:#a1a1aa; }
.lw-btn { height:44px; border:none; border-radius:10px; background:linear-gradient(135deg,#667eea,#764ba2); color:#fff; font-size:15px; font-weight:580; font-family:inherit; cursor:pointer; }
.lw-forgot { text-align:right; margin-top:12px; }
.lw-forgot a { font-size:13px; color:#71717a; cursor:pointer; }
.lw-hint { font-size:13px; color:#ff3b30; min-height:18px; margin-top:12px; text-align:center; }
'@

$newCSS = @"
/* ── Login Wall ── */
.login-wall { position:fixed; inset:0; z-index:9999; background:linear-gradient(160deg,#f0f0f5,#e8e8f0); display:flex; align-items:center; justify-content:center; padding:20px; }
.lw-card { width:360px; max-width:100%; background:#fff; border-radius:18px; box-shadow:0 4px 24px rgba(0,0,0,.08); padding:28px 32px 24px; display:flex; flex-direction:column; }
.lw-header { text-align:center; margin-bottom:24px; }
.lw-title { font-size:20px; font-weight:500; color:#1d1d1f; }
.lw-desc { font-size:13px; color:#71717a; margin-top:6px; }
.lw-fields { display:flex; flex-direction:column; gap:14px; }
.lw-field { position:relative; height:56px; }
.lw-label { position:absolute; top:50%; left:14px; transform:translateY(-50%); font-size:14px; color:#a1a1aa; pointer-events:none; transition:all .15s ease; }
.lw-field:focus-within .lw-label, .lw-field.has-value .lw-label { top:8px; font-size:11px; transform:none; color:#667eea; }
.lw-field input { width:100%; height:100%; padding:22px 14px 8px; border:2px solid #e4e4e7; border-radius:10px; font-size:14px; font-family:inherit; color:#1d1d1f; outline:none; transition:border-color .15s; }
.lw-field:focus-within input { border-color:#667eea; }
.lw-field input::placeholder { color:transparent; }
.lw-field:focus-within input::placeholder, .lw-field.has-value input::placeholder { color:#a1a1aa; }
.lw-btn { height:40px; border:none; border-radius:10px; background:#667eea; color:#fff; font-size:14px; font-weight:500; font-family:inherit; cursor:pointer; display:flex; align-items:center; justify-content:center; gap:6px; }
.lw-btn:hover { background:#5a6fd6; }
.lw-forgot { text-align:right; margin:8px 0 16px; }
.lw-forgot a { font-size:13px; color:#71717a; cursor:pointer; }
.lw-divider { display:flex; align-items:center; gap:12px; margin:16px 0; color:#a1a1aa; font-size:12px; }
.lw-divider::before, .lw-divider::after { content:''; flex:1; height:1px; background:#e4e4e7; }
.lw-register { text-align:center; font-size:13px; color:#71717a; }
.lw-register a { color:#667eea; cursor:pointer; }
.lw-hint { font-size:13px; color:#ff3b30; min-height:18px; margin-top:12px; text-align:center; }
"@

$c = $c.Replace($oldCSS, $newCSS)
[System.IO.File]::WriteAllText("D:\demo\index.html", $c, [System.Text.Encoding]::UTF8)
Write-Host "CSS updated"