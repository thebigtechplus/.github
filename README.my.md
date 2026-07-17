<h1 align="center">BigTech+ <code>.github</code> repository</h1>

<p align="center">
  <a href="README.md">English</a> | <b>မြန်မာ</b>
</p>

> မြန်မာဘာသာပြန်နှင့် အင်္ဂလိပ်မူရင်း ကွဲလွဲမှုရှိပါက အင်္ဂလိပ်မူရင်းကိုသာ အတည်ယူပါ။

[BigTech+](https://github.com/thebigtechplus) organization အတွက် တရားဝင် GitHub default များနှင့် အင်ဂျင်နီယာဆိုင်ရာ စံချိန်စံညွှန်းများ ဖြစ်ပါတယ်။

BigTech+ သည် အဓိကအားဖြင့် **private** organization ဖြစ်သည်။ Organization တစ်ခုလုံးအတွက် default ဖြစ်သော community health ဖိုင်များနှင့် issue/PR template များ အလုပ်လုပ်စေရန်အတွက် GitHub က public ဖြစ်ရန် သတ်မှတ်ထားသောကြောင့် ဤ repository ကို **public** အဖြစ် ထားရှိထားခြင်း ဖြစ်ပါတယ်။

## အလိုအလျောက် ဆက်ခံအသုံးပြုနိုင်သည့်အချက်အလက်များ

သီးခြား ကိုယ်ပိုင် copy များ မသတ်မှတ်ထားသော repository များသည် အောက်ပါအချက်အလက်တို့ကို ဆက်ခံအသုံးပြုနိုင်ပါတယ် —

| Path | ရည်ရွယ်ချက် |
| --- | --- |
| [`CODE_OF_CONDUCT.my.md`](CODE_OF_CONDUCT.my.md) | လိုက်နာရမည့် ကျင့်ဝတ် |
| [`CONTRIBUTING.my.md`](CONTRIBUTING.my.md) | Branching၊ commit နှင့် review လုပ်ငန်းစဉ် |
| [`SECURITY.my.md`](SECURITY.my.md) | လုံခြုံရေးဆိုင်ရာ ပြဿနာများ တင်ပြနည်း |
| [`SUPPORT.my.md`](SUPPORT.my.md) | အကူအညီ ရယူနိုင်သည့်နေရာ |
| [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) | Bug နှင့် feature issue form များ |
| [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) | Pull request checklist |

## ဆက်ခံအသုံးပြု၍ မရသည့်အချက်အလက်များ

လိုအပ်သည့်အခါ အောက်ပါတို့ကို product repository တစ်ခုစီထဲသို့ ကူးထည့်ပါ (သို့မဟုတ် ထို repo တွင် ပြင်ဆင်သတ်မှတ်ပါ) —

| Path | ရည်ရွယ်ချက် |
| --- | --- |
| [`CODEOWNERS`](CODEOWNERS) | Review ownership (`@thebigtechplus/admins`) |
| [`scripts/templates/`](scripts/templates/) | Bootstrap အတွက် README၊ AGENTS၊ CLAUDE၊ proprietary LICENSE၊ pre-commit template များ |
| [`.github/dependabot.yml`](.github/dependabot.yml) | Dependency update automation |
| `.github/workflows/` အောက်ရှိ workflow များ | CI/CD (product များ လိုအပ်လာမှသာ workflow များ ထည့်ပါ) |

issue form များကို ဆက်ခံအသုံးပြုပါက သုံးမည့် repository တစ်ခုစီတွင် issue form label များ (`bug`၊ `enhancement`) လည်း ရှိရပါမယ်။

## Repository အသစ်များ

**[GitHub CLI](https://cli.github.com/)** (`gh`) **လိုအပ်ပါတယ်**။ Repo **တစ်ခုချင်းစီသာ** bootstrap လုပ်ပါ (repo အားလုံးကို အလိုအလျောက် သက်ရောက်ခြင်း မရှိပါ)။

Extension ကို တစ်ကြိမ်သာ install လုပ်ရန် —

```bash
gh extension install thebigtechplus/gh-bootstrap-repo
```

ထို့နောက် မည်သည့်နေရာမှမဆို —

```bash
gh bootstrap-repo <repo-name> --create              # private (default)
gh bootstrap-repo <repo-name> --create --public     # public
```

One-liner script များနှင့် အသေးစိတ်ကို [`docs/new-repo.my.md`](docs/new-repo.my.md) တွင် ဖတ်ပါ။

## Profile

[`profile/README.md`](profile/README.md) ကို [github.com/thebigtechplus](https://github.com/thebigtechplus) မှာ ပြသထားပါတယ်။

## Website

- [www.bigtechplus.io](https://www.bigtechplus.io)
