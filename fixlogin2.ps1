$c=[System.IO.File]::ReadAllText("D:\demo\index.html",[System.Text.Encoding]::UTF8)

# Update login HTML
$old = 'id="loginWall"'
$idx = $c.IndexOf($old)
$end = $c.IndexOf('<!-- App shell -->', $idx)
$oldHTML = $c.Substring($idx, $end - $idx)

$newHTML = 'id="loginWall">
  <div class="lw-card">
    <div class="lw-header"><div class="lw-title">信拓</div><div class="lw-desc">抖店 · 客户注册工作台</div></div>
    <div class="lw-fields">
      <div class="lw-field"><label class="lw-label">手机号</label><input id="lw_phone" type="text" placeholder="请输入手机号" maxlength="11" inputmode="numeric"></div>
      <div class="lw-field"><label class="lw-label">密码</label><input id="lw_pass" type="password" placeholder="请输入密码"></div>
    </div>
    <div class="lw-forgot"><a>忘记密码了？</a></div>
    <button class="lw-btn" id="lw_btn"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h4a2 2 0 012 2v14a2 2 0 01-2 2h-4"/><polyline points="10 17 15 12 10 7"/><line x1="15" y1="12" x2="3" y2="12"/></svg>登录</button>
    <div class="lw-divider"><span>或</span></div>
    <div class="lw-register">还没有账号？ <a>首次登录自动注册</a></div>
    <div class="lw-hint" id="lw_hint"></div>
  </div>
</div>
'@

$c = $c.Replace($oldHTML, $newHTML)
[System.IO.File]::WriteAllText("D:\demo\index.html", $c, [System.Text.Encoding]::UTF8)
Write-Host "HTML updated"