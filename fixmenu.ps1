$c = [System.IO.File]::ReadAllText("D:\demo\index.html", [System.Text.Encoding]::UTF8)

$start = $c.IndexOf("function showAuthModal() {")
$end = $c.IndexOf("function closeUserMenu", $start)
if ($end -lt 0) { $end = $c.IndexOf("function toggleSearch()", $start) }

$newFunc = @'
function showAuthModal() {
  if (!currentUser) return;
  var old = document.querySelector(".user-menu");
  if (old) { old.remove(); return; }
  var btn = document.getElementById("authBtn");
  var rect = btn.getBoundingClientRect();
  var menu = document.createElement("div");
  menu.className = "user-menu";
  var right = Math.max(8, window.innerWidth - rect.right);
  menu.style.cssText = "position:fixed;top:"+(rect.bottom+6)+"px;right:"+right+"px;z-index:1000;background:#fff;border-radius:14px;box-shadow:0 4px 24px rgba(0,0,0,.12),0 0 0 1px rgba(0,0,0,.04);padding:6px;min-width:180px;";
  var html = "<div style=3'padding:8px 12px 6px;'><div style=3'font-size:13px;font-weight:600;color:#1d1d1f;'>"+currentUser+"</div>"+(isAdmin?"<div style=3'font-size:11px;color:#667eea;'>管理员</div>":"")+"</div><div style=3'height:1px;background:#f0f0f0;margin:4px 0;'></div>";
  if (isAdmin) { html += "<button class=3'um-item' onclick=3'closeUserMenu();showAdminPanel()'>用户审批</button><button class=3'um-item' onclick=3'closeUserMenu();showNicknameModal()'>设置昵称</button>"; }
  html += "<button class=3'um-item' onclick=3'closeUserMenu();showChangePassModal()'>修改密码</button><button class=3'um-item um-item--danger' onclick=3'closeUserMenu();confirmDialog(/'退出登录 "+currentUser+"？/',function(){currentUser=/';localStorage.removeItem(/qdou_user/q);clients=[];localStorage.removeItem(/qdoudian_clients/q);updateAuthBtn();document.getElementById(/qappShell/q).style.display=/qnone/q;document.getElementById(/qloginWall/q).style.display=/q/q;})'>退出登录</button>";
  menu.innerHTML = html;
  document.body.appendChild(menu);
  setTimeout(function(){ document.addEventListener("click",function close(e){ if(!menu.contains(e.target)&&e.target!==btn){ menu.remove();document.removeEventListener("click",close); } }); },10);
}
function closeUserMenu(){ var m=document.querySelector(".user-menu"); if(m)m.remove(); }
'@

# Fix quotes in the template
$newFunc = $newFunc.Replace('=3', '="').Replace('/q', "'").Replace("'", '"').Replace('="', "='")
# Actually let me just write it properly

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

$c = $c.Remove($start, $end - $start).Insert($start, $newFunc)
[System.IO.File]::WriteAllText("D:\demo\index.html", $c, [System.Text.Encoding]::UTF8)
Write-Host "Fixed showAuthModal"