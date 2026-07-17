> Read in English — [new-repo.md](new-repo.md)
>
> မြန်မာဘာသာပြန်နှင့် အင်္ဂလိပ်မူရင်း ကွဲလွဲမှုရှိပါက အင်္ဂလိပ်မူရင်းကိုသာ အတည်ယူပါ။

# Repository အသစ် ဆောက်ရန် checklist

**[GitHub CLI](https://cli.github.com/)** (`gh`) **လိုအပ်ပြီး** `thebigtechplus` ကို ဝင်ရောက်ခွင့်ရှိသော account ဖြင့် authenticate လုပ်ထားရပါမယ်။ Developer အားလုံးသည် ဤ workflow အတွက် `gh` ကို အသုံးပြုကြပါတယ်။

Repo အသစ်တွင် သက်ဆိုင်ရာ သီးခြား ကိုယ်ပိုင် copy များ မသတ်မှတ်ထားပါက organization default များ (issue/PR template များ၊ `CONTRIBUTING`၊ `SECURITY`၊ `SUPPORT`၊ `CODE_OF_CONDUCT`) ကို [thebigtechplus/.github](https://github.com/thebigtechplus/.github) မှ ဆက်ခံအသုံးပြုပါတယ်။ ဤ `.github` repository ကို **public** အဖြစ် ဆက်ထားပါ။

## အကြံပြုထားသည့်နည်းလမ်း — `gh` extension (မည်သည့်နေရာမှမဆို)

တစ်ကြိမ်သာ install လုပ်ရန် —

```bash
gh extension install thebigtechplus/gh-bootstrap-repo
```

ထို့နောက် မည်သည့် directory မှမဆို repository **တစ်ခုချင်းစီ** bootstrap လုပ်ပါ —

```bash
gh bootstrap-repo api --create              # private (default)
gh bootstrap-repo oss-demo --create --public
gh bootstrap-repo web                       # configure existing repo
```

Extension ကို upgrade လုပ်ရန် —

```bash
gh extension upgrade bootstrap-repo
```

ဤ command သည် repo အားလုံးကို အလိုအလျောက် သက်ရောက်ခြင်း **မရှိပါ**။ ထို့ကြောင့် Repository အသစ်တစ်ခုစီအတွက် ထပ်မံ run ပေးရပါမယ်။

Extension source — [thebigtechplus/gh-bootstrap-repo](https://github.com/thebigtechplus/gh-bootstrap-repo)။

## အခြားနည်းလမ်း — one-liner များ (`gh` လိုအပ်နေဆဲ)

Remote script များသည် `gh` ကို အတွင်းပိုင်းတွင် ခေါ်သုံးထားပါတယ်။ ဦးစွာ `gh` ကို install လုပ်ပြီး authenticate လုပ်ထားရပါမယ်။

```bash
# macOS / Linux / Git Bash / WSL
curl -fsSL https://raw.githubusercontent.com/thebigtechplus/.github/main/scripts/bootstrap-repo.sh | bash -s -- api --create
```

```powershell
# Windows PowerShell
$script = Join-Path $env:TEMP 'btp-bootstrap-repo.ps1'
Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/thebigtechplus/.github/main/scripts/bootstrap-repo.ps1' -OutFile $script
pwsh -File $script api -Create
```

## Local clone (optional)

ဤ repo ကို checkout လုပ်ပြီးသား ဖြစ်ပါက —

| Platform                       | Command                                                 |
| ------------------------------ | ------------------------------------------------------- |
| macOS / Linux / Git Bash / WSL | `./scripts/bootstrap-repo.sh <repo-name> --create`      |
| Windows (PowerShell)           | `pwsh ./scripts/bootstrap-repo.ps1 <repo-name> -Create` |

## Bootstrap က အလိုအလျောက် ပြင်ဆင်သတ်မှတ်ပေးသည့်အရာများ

- Label များ — `bug`၊ `enhancement`၊ `dependencies`၊ `github-actions`
- Root `CODEOWNERS` → `@thebigtechplus/admins` (**မရှိမှသာ** အလိုအလျောက် ထည့်ပေးပါတယ်)
- Team ဝင်ရောက်ခွင့် — `developers` (write)၊ `admins` (admin)
- `README.md`၊ `AGENTS.md`၊ `CLAUDE.md` ([`scripts/templates/`](../scripts/templates/) မှ — **မရှိမှသာ** အလိုအလျောက် ထည့်ပေးပါတယ်)
- `LICENSE` — proprietary / all rights reserved (template မှ — **မရှိမှသာ** အလိုအလျောက် ထည့်ပေးပါတယ်။ တိုင်ပင်ဆွေးနွေးပြီး ရည်ရွယ်ချက်ရှိရှိ open source လုပ်မှသာ အစားထိုးပါ)
- `.pre-commit-config.yaml`၊ `.markdownlint.yaml` (template မှ — **မရှိမှသာ** အလိုအလျောက် ထည့်ပေးပါတယ်)
- Squash-only merge၊ merge ပြီးလျှင် branch ဖျက်ခြင်း၊ wiki ပိတ်ခြင်း
- Branch protection — bootstrap က **မသတ်မှတ်ပေးပါ**၊ bootstrap run ပြီးချိန်တွင် ပြသသော GitHub web UI guide (သို့မဟုတ် အောက်ပါအပိုင်း) အတိုင်း လုပ်ဆောင်ပါ

`AGENTS.md` သည် AI tool များ (Claude, Codex, Cursor) အတွက် တရားဝင် guideline ဖိုင် ဖြစ်သည်။ `CLAUDE.md` သည် Claude Code အတွက်သာဖြစ်ပြီး `@AGENTS.md` ကိုသာ import လုပ်ပါတယ် — ထိုဖိုင်တွင် agent instruction စည်းမျဉ်းများ ထပ်မရေးပါနှင့်။

Bootstrap ပြီးနောက် pre-commit ကို local တွင် install လုပ်ပါ —

```bash
pip install pre-commit

pre-commit install
pre-commit run --all-files
```

Template များကို [scripts/templates/](../scripts/templates/) တွင် ကြည့်နိုင်ပါတယ်။

## Manual checklist (အထက်ပါအဆင့်များအတိုင်း ကိုယ်တိုင်လုပ်ရန်)

### 1. Repository ဆောက်ခြင်း

- Owner — `thebigtechplus`
- Visibility — **Private** (ဆွေးနွေးတိုင်ပင်ပြီး ရည်ရွယ်ချက်ရှိရှိ open source လုပ်မည့် repo မှလွဲ၍)
- Default branch — `main`
- Org default များကို override လုပ်ရန် ရည်ရွယ်ချက်မရှိပါက local `.github/ISSUE_TEMPLATE/` folder **မထည့်ပါနှင့်**

### 2. CODEOWNERS ကူးထည့်ခြင်း

Org `CODEOWNERS` သည် default မှ ဆက်ခံအသုံးပြုခြင်း မရှိပါ။ Root တွင် `CODEOWNERS` ဖိုင် ထည့်ပါ —

```text
* @thebigtechplus/admins
```

### 3. Label များ ဆောက်ခြင်း

| Name | Suggested color | ရည်ရွယ်ချက် |
| --- | --- | --- |
| `bug` | `#d73a4a` | Bug report များ |
| `enhancement` | `#a2eeef` | Feature request များ |
| `dependencies` | `#0366d6` | Dependency update များ (Dependabot သုံးပါက) |
| `github-actions` | `#2088FF` | Actions နှင့်သက်ဆိုင်သော Dependabot PR များ (optional) |

### 4. `main` အတွက် branch protection (manual)

Bootstrap ပြီးဆုံးချိန်တွင် link နှင့် checklist ကို ပြသပေးသည်။ Repository web UI တွင် ပြင်ဆင်သတ်မှတ်ပါ —

**Settings → Rules → Rulesets** (classic rule များအတွက် **Settings → Branches**) —
`https://github.com/thebigtechplus/<repo-name>/settings/rules`

`main` အတွက် အကြံပြုချက်များ —

- Merge မလုပ်မီ pull request လိုအပ်ကြောင်း သတ်မှတ်ခြင်း
- Required approvals — အနည်းဆုံး 1 ခု
- Code Owners ထံမှ review လိုအပ်ကြောင်း သတ်မှတ်ခြင်း (`CODEOWNERS` ရှိပြီးနောက်)
- Commit အသစ် push လုပ်လျှင် stale approval များကို ပယ်ဖျက်ခြင်း
- Merge မလုပ်မီ conversation resolution လိုအပ်ကြောင်း သတ်မှတ်ခြင်း
- Force push နှင့်တကွ deletion များကို ကန့်သတ်ခြင်း

**GitHub Free Plan** တွင် **private** org repository များအတွက် branch protection သုံးရန် organization ကို **GitHub Team** သို့ upgrade လုပ်ရန် သို့မဟုတ် repository ကို **public** ပြောင်းရန် လိုအပ်နိုင်ပါတယ်။ Public repository များသာ Free Plan တွင် branch protection ကို အသုံးပြုနိုင်ပါတယ်။

### 5. Optional — Dependabot

လိုအပ်သည့်အခါ [`.github/dependabot.yml`](../.github/dependabot.yml) ကို product repository ထဲသို့ ကူးထည့်ပါ။

### 6. Optional — CI

Lint/test/build check များ ရှိလာသည့်အခါ `.github/workflows/` အောက်တွင် workflow များ ထည့်ပါ။ Placeholder workflow များ မထည့်ပါနှင့်။

### 7. Default ဆက်ခံအသုံးပြုမှုကို စစ်ဆေးခြင်း (smoke-check)

1. **New issue** — Bug Report နှင့် Feature Request တို့ ပေါ်လာရပါမယ်။
2. Test PR တစ်ခုဖွင့်ပါ — PR template ပေါ်လာရပါမယ်။

Issue chooser ဗလာဖြစ်နေပါက repo တွင် org default များကို override လုပ်နေသော ကိုယ်ပိုင် `.github/ISSUE_TEMPLATE/` ရှိနေလို့ ဖြစ်နိုင်ပါတယ်။
