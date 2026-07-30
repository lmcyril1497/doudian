$c = [System.IO.File]::ReadAllText("D:\demo\index.html", [System.Text.Encoding]::UTF8)

# showAuthModal starts at offset 46677
# showAuthModal ends at offset 47300 (after "});" at line 1304)
# Find the exact end: "  });\n}" after the old login code
$oldStart = $c.IndexOf('function showAuthModal() {')
$oldEnd = $c.IndexOf('function initAdminSelect', $oldStart)
if ($oldEnd -lt 0) {
    # Find the closing } of the function - it's at line 1304
    $oldEnd = $c.IndexOf("refreshAll();`n  });`n}", $oldStart) + 19
}
if ($oldEnd -lt 19) {
    # Try another pattern
    $line1304 = $c.IndexOf("refreshAll();", $oldStart)
    $oldEnd = $c.IndexOf("}", $line1304) + 1
}

Write-Host "Start: $oldStart, End: $oldEnd, Length: $($oldEnd - $oldStart)"

$newFunc = @"
function showAuthModal() {
  if (!currentUser) return;
  var old = document.querySelector('.user-menu');
  if (old) { old.remove(); return; }
  var btn = document.getElementById('authBtn');
  var rect = btn.getBoundingClientRect();
  var menu = document.createElement('div');
  menu.className = 'user-menu';
  var right = Math.max(8, window.innerWidth - rect.right);
  menu.style.cssText = 'position:fixed;top:'+(rect.bottom+6)+'px;right:'+right+'px;z-index:1000;background:#fff;border-radius:14px;box-shadow:0 4px 24px rgba(0,0,0,.12),0 0 0 1px rgba(0,0,0,.04);padding:6px;min-width:180px;';
  var html = '<div style="padding:8px 12px 6px;"><div style="font-size:13px;font-weight:600;color:#1d1d1f;">'+currentUser+'</div>'+(isAdmin?'<div style="font-size:11px;color:#667eea;">管理员</div>':'')+'</div><div style="height:1px;background:#f0f0f0;margin:4px 0;"></div>';
  if (isAdmin) { html += '<button class="um-item" onclick="closeUserMenu();showAdminPanel()">用户审批</button><button class="um-item" onclick="closeUserMenu();showNicknameModal()">设置昵称</button>'; }
  html += '<button class="um-item" onclick="closeUserMenu();showChangePassModal()">修改密码</button><button class="um-item um-item--danger" onclick="closeUserMenu();confirmDialog(\'退出登录 '+currentUser+'？\',function(){currentUser=\'\';localStorage.removeItem(\'dou_user\');clients=[];localStorage.removeItem(\'doudian_clients\');updateAuthBtn();document.getElementById(\'appShell\').style.display=\'none\';document.getElementById(\'loginWall\').style.display=\'\';})">退出登录</button>';
  menu.innerHTML = html;
  document.body.appendChild(menu);
  setTimeout(function(){ document.addEventListener('click',function close(e){ if(!menu.contains(e.target)&&e.target!==btn){ menu.remove();document.removeEventListener('click',close); } }); },10);
}
function closeUserMenu(){ var m=document.querySelector('.user-menu'); if(m)m.remove(); }
"@

$c = $c.Remove($oldStart, $oldEnd - $oldStart).Insert($oldStart, $newFunc)
[System.IO.File]::WriteAllText("D:\demo\index.html", $c, [System.Text.Encoding]::UTF8)
Write-Host "Fixed!"