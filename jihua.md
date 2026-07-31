# P0 安全修复实现方案

## 1. 背景与问题

本项目是单文件看板应用 `index.html`，使用 Supabase 作为后端（认证 + REST API）。经代码审计发现以下严重安全问题：

| 编号 | 问题 | 严重程度 | 位置 |
|------|------|---------|------|
| P0-1 | Supabase Service Role Key 可能暴露在前端 | 严重 | `index.html:2295` |
| P0-2 | 管理员状态 `isAdmin`/`isSuperAdmin` 存储在 localStorage，客户端可任意篡改 | 严重 | `index.html:1678-1679` |
| P0-3 | 密码重置函数 `resetUserPwd()` 直接调用 Supabase Admin API，用 `window._serviceRoleKey\|\|SB_KEY` 做认证 | 严重 | `index.html:2287-2308` |
| P0-4 | `showResetPwd()` 中 PATCH users 表只用了 `apikey`，缺少 Authorization token | 高 | `index.html:1810` |
| P0-5 | RLS（行级安全策略）可能未正确配置，用户可直接调 API 跨用户读写数据 | 严重 | Supabase 数据库 |

---

## 2. 修复目标

1. **Service Role Key 不再出现在前端任何位置**
2. **密码重置通过 Edge Function 中转**，key 存在服务端环境变量
3. **管理员状态不持久化到 localStorage**，每次从 users 表查
4. **RLS 策略保障**：普通用户只能操作自己的数据，admin 可操作所有

---

## 3. 涉及文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `index.html` | 修改 | 移除 service role key 引用，改密码重置调用方式，移除 localStorage admin 持久化 |
| `supabase/functions/reset-password/index.ts` | 新建 | Edge Function：验证管理员身份后重置密码 |
| `supabase/config.toml` | 新建 | Supabase 项目配置（可选） |

---

## 4. index.html 修改详情

### 4.1 移除 `window._serviceRoleKey` 所有引用

搜索 `window._serviceRoleKey`，共出现 1 处（第 2295 行），删除该引用。

### 4.2 修改 `resetUserPwd()` 函数（第 2287-2308 行）

**当前代码逻辑：**
```
1. 查 users 表获取 uid
2. 直接调用 /auth/v1/admin/users/{uid}/password（用 service role key）
3. 成功则更新 users 表的 reset_requested
```

**修改后逻辑：**
```
1. 查 users 表获取 uid
2. 调用 Edge Function POST /functions/v1/reset-password，body: { user_id, new_password }
3. Edge Function 内部验证调用者是 admin，再用 service role key 执行重置
4. 成功则更新 users 表的 reset_requested
```

**修改后的代码：**
```js
async function resetUserPwd(id){
  try{
    var r=await fetch(SB_URL+"/rest/v1/users?email=eq."+encodeURIComponent(id)+"&select=id",{headers:sbHead()});
    var u=await r.json();
    if(!u||u.length===0){toast('用户不存在','error');return;}
    var uid=u[0].id;
    var sr=await fetch(SB_URL+"/functions/v1/reset-password",{
      method:"POST",
      headers:{
        apikey:SB_KEY,
        Authorization:"Bearer "+_sessionToken,
        "Content-Type":"application/json"
      },
      body:JSON.stringify({user_id:uid,new_password:"123456"})
    });
    if(!sr.ok){
      var errData=await sr.json().catch(function(){return{};});
      toast(errData.error||"重置失败，请稍后重试","error");
      return;
    }
    await fetch(SB_URL+"/rest/v1/users?email=eq."+encodeURIComponent(id),{method:"PATCH",headers:sbHead(),body:JSON.stringify({reset_requested:false})});
    toast(id+' 密码已重置为 123456','success');closeAdminPopup();showAdminPanel();
  }catch(e){
    toast('操作失败，请在 Supabase Dashboard 手动重置','error');
  }
}
```

### 4.3 修改 `showResetPwd()` 中的 PATCH 调用（第 1810 行）

**当前代码：**
```js
headers:{apikey:SB_KEY,'Content-Type':'application/json'}
```

**修改为：**
```js
headers:{apikey:SB_KEY,Authorization:'Bearer '+_sessionToken,'Content-Type':'application/json'}
```

### 4.4 移除 localStorage 中 admin/super 标志的持久化

以下是所有需要修改的位置：

#### 4.4.1 第 1678-1679 行（全局变量声明）

**当前：**
```js
let currentUser = localStorage.getItem('dou_user') || '';
let isAdmin = !!localStorage.getItem('dou_admin');
let isSuperAdmin = !!localStorage.getItem('dou_super');
```

**改为：**
```js
let currentUser = localStorage.getItem('dou_user') || '';
let isAdmin = false;
let isSuperAdmin = false;
```

> 说明：`currentUser` 保留 localStorage 是因为需要页面刷新后恢复登录状态，但 `isAdmin`/`isSuperAdmin` 必须从 users 表重新查。

#### 4.4.2 第 1861 行（登录成功后存储角色）

**当前：**
```js
localStorage.setItem("dou_admin",isAdmin?"1":"");
localStorage.setItem("dou_super",isSuperAdmin?"1":"");
```

**改为：** 删除这两行

#### 4.4.3 第 1911-1912 行（审批轮询通过后存储角色）

**当前：**
```js
localStorage.setItem("dou_admin",isAdmin?"1":"");
localStorage.setItem("dou_super",isSuperAdmin?"1":"");
```

**改为：** 删除这两行

#### 4.4.4 第 2400-2401 行（转移主账号后）

**当前：**
```js
localStorage.setItem('dou_super','');
localStorage.setItem('dou_admin','1');
```

**改为：** 删除这两行

#### 4.4.5 第 4429-4430 行（页面初始化恢复角色）

**当前：**
```js
localStorage.setItem('dou_super', isSuperAdmin?'1':'');
localStorage.setItem('dou_admin', isAdmin ? '1' : '');
```

**改为：** 删除这两行

> 说明：第 4428 行已经从 users 表查询了角色并赋值给 `isAdmin`/`isSuperAdmin`，这里不需要再写 localStorage。

---

## 5. 新建 Edge Function

### 5.1 目录结构

```
supabase/
├── config.toml
└── functions/
    └── reset-password/
        └── index.ts
```

### 5.2 `supabase/functions/reset-password/index.ts`

```ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  // 处理 CORS 预检
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. 从请求中获取用户 JWT
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "未授权" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 2. 用 anon key 创建客户端，验证 JWT 并查询用户角色
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 用用户 JWT 验证身份
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();

    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: "身份验证失败" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 3. 查 users 表确认是 admin 或 owner
    const { data: userData, error: userError } = await userClient
      .from("users")
      .select("role, status")
      .eq("email", user.email)
      .single();

    if (userError || !userData || userData.status !== "approved") {
      return new Response(
        JSON.stringify({ error: "用户未通过审批" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (userData.role !== "admin" && userData.role !== "owner") {
      return new Response(
        JSON.stringify({ error: "无管理员权限" }),
        { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 4. 解析请求 body
    const { user_id, new_password } = await req.json();

    if (!user_id || !new_password) {
      return new Response(
        JSON.stringify({ error: "缺少 user_id 或 new_password" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (new_password.length < 6) {
      return new Response(
        JSON.stringify({ error: "密码至少6位" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 5. 用 service role key 调用 Supabase Auth Admin API 重置密码
    const adminResponse = await fetch(
      `${supabaseUrl}/auth/v1/admin/users/${user_id}/password`,
      {
        method: "POST",
        headers: {
          apikey: serviceRoleKey,
          Authorization: `Bearer ${serviceRoleKey}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ password: new_password }),
      }
    );

    if (!adminResponse.ok) {
      const errText = await adminResponse.text();
      console.error("Reset password failed:", errText);
      return new Response(
        JSON.stringify({ error: "密码重置失败" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Edge Function error:", err);
    return new Response(
      JSON.stringify({ error: "服务器内部错误" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
```

---

## 6. Supabase Dashboard 操作（RLS 策略）

### 6.1 执行位置

Supabase Dashboard → SQL Editor → 新建查询

### 6.2 SQL 内容

```sql
-- ========================================
-- 1. 确保 RLS 启用
-- ========================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- ========================================
-- 2. users 表策略
-- ========================================

-- 策略 1：所有已登录用户可读（用于查昵称、用户列表等）
DROP POLICY IF EXISTS "users_select_authenticated" ON public.users;
CREATE POLICY "users_select_authenticated" ON public.users
  FOR SELECT
  USING (auth.role() = 'authenticated');

-- 策略 2：用户只能 INSERT 自己的注册记录（id 必须等于 auth.uid）
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT
  WITH CHECK (id::text = auth.uid()::text);

-- 策略 3：只有 admin/owner 可以 UPDATE（审批、设角色、改昵称等）
DROP POLICY IF EXISTS "admin_update_users" ON public.users;
CREATE POLICY "admin_update_users" ON public.users
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users AS admin_user
      WHERE admin_user.email = auth.email()
        AND admin_user.status = 'approved'
        AND (admin_user.role = 'admin' OR admin_user.role = 'owner')
    )
  );

-- 策略 4：只有 admin/owner 可以 DELETE（或标记 rejected）
DROP POLICY IF EXISTS "admin_delete_users" ON public.users;
CREATE POLICY "admin_delete_users" ON public.users
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users AS admin_user
      WHERE admin_user.email = auth.email()
        AND admin_user.status = 'approved'
        AND (admin_user.role = 'admin' OR admin_user.role = 'owner')
    )
  );

-- ========================================
-- 3. clients 表策略
-- ========================================

-- 策略 1：普通用户只能读自己的；admin/owner 可读所有
DROP POLICY IF EXISTS "clients_select" ON public.clients;
CREATE POLICY "clients_select" ON public.clients
  FOR SELECT
  USING (
    user_id = auth.email()
    OR EXISTS (
      SELECT 1 FROM public.users AS u
      WHERE u.email = auth.email()
        AND u.status = 'approved'
        AND (u.role = 'admin' OR u.role = 'owner')
    )
  );

-- 策略 2：用户只能 INSERT 自己的
DROP POLICY IF EXISTS "clients_insert" ON public.clients;
CREATE POLICY "clients_insert" ON public.clients
  FOR INSERT
  WITH CHECK (user_id = auth.email());

-- 策略 3：用户只能 UPDATE 自己的；admin/owner 可更新所有
DROP POLICY IF EXISTS "clients_update" ON public.clients;
CREATE POLICY "clients_update" ON public.clients
  FOR UPDATE
  USING (
    user_id = auth.email()
    OR EXISTS (
      SELECT 1 FROM public.users AS u
      WHERE u.email = auth.email()
        AND u.status = 'approved'
        AND (u.role = 'admin' OR u.role = 'owner')
    )
  );

-- 策略 4：用户只能 DELETE 自己的；admin/owner 可删除所有
DROP POLICY IF EXISTS "clients_delete" ON public.clients;
CREATE POLICY "clients_delete" ON public.clients
  FOR DELETE
  USING (
    user_id = auth.email()
    OR EXISTS (
      SELECT 1 FROM public.users AS u
      WHERE u.email = auth.email()
        AND u.status = 'approved'
        AND (u.role = 'admin' OR u.role = 'owner')
    )
  );
```

### 6.3 执行前检查（可选但推荐）

先查看当前已有的策略，避免冲突：

```sql
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename IN ('users', 'clients')
ORDER BY tablename, policyname;
```

---

## 7. Edge Function 环境变量配置

Supabase Dashboard → Settings → Edge Functions → Environment Variables

添加：

| 变量名 | 值 |
|--------|-----|
| `SUPABASE_SERVICE_ROLE_KEY` | 从 Settings → API → service_role key 复制 |

---

## 8. 部署步骤

### 步骤 1：安装 Supabase CLI（如未安装）

```bash
npm install -g supabase
```

### 步骤 2：登录 Supabase

```bash
supabase login
```

### 步骤 3：关联项目

```bash
supabase link --project-ref ytqzuqqqytdihxybhhcy
```

### 步骤 4：部署 Edge Function

```bash
supabase functions deploy reset-password
```

### 步骤 5：设置环境变量

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=eyJ...你的service_role_key
```

或在 Dashboard → Settings → Edge Functions 手动添加。

### 步骤 6：执行 RLS SQL

在 Dashboard → SQL Editor 执行第 6 节的 SQL。

### 步骤 7：修改 index.html

按第 4 节的 5 处改动修改代码。

### 步骤 8：测试

1. 用管理员账号登录
2. 打开权限管理 → 尝试重置某用户密码
3. 确认返回成功，用新密码登录测试
4. 用普通用户登录，尝试直接调 API 删除其他用户数据 → 应被 RLS 拒绝

---

## 9. 验证清单

| 验证项 | 预期结果 |
|--------|---------|
| 搜索 `index.html` 中 `service_role` 关键字 | 无结果 |
| 搜索 `window._serviceRoleKey` 关键字 | 无结果 |
| 管理员重置密码 | 成功，密码变为 123456 |
| 普通用户调 `DELETE /rest/v1/clients?user_id=eq.other` | 返回 403 或空数据 |
| 页面刷新后 `isAdmin` 仍正确 | 从 users 表重新查，不从 localStorage 恢复 |
| 控制台执行 `localStorage.setItem('dou_admin','1')` | 刷新后无效，admin 状态不被篡改 |

---

## 10. 风险与回退方案

| 风险 | 影响 | 应对 |
|------|------|------|
| RLS 策略阻止 admin 查询 `?select=*` | admin 视图无法加载所有用户数据 | RLS 中 admin/owner 的 SELECT 策略用 `EXISTS` 子查询放行，已覆盖 |
| Edge Function 冷启动延迟 | 首次调用约 1-2 秒 | 密码重置低频操作，可接受 |
| `_sessionToken` 过期 | Edge Function 返回 401 | 调用前已有 `refreshSession()`，如仍失败 toast 提示用户重新登录 |
| 现有功能被 RLS 意外阻断 | 比如 `switchToUserView` 查其他用户数据 | admin/owner 策略已放行；需测试确认 |

---

## 11. 后续可优化（非 P0）

- 密码重置后强制用户首次登录修改密码（`force_password_change` 字段）
- 前端登录防暴力破解（按钮节流 + Supabase rate limiting）
- Content Security Policy (CSP) meta 标签
- 用 Edge Function 包裹所有管理操作（审批、角色变更等）
