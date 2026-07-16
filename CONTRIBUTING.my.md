> Read in English — [CONTRIBUTING.md](CONTRIBUTING.md)
>
> မြန်မာဘာသာပြန်နှင့် အင်္ဂလိပ်မူရင်း ကွဲလွဲမှုရှိပါက အင်္ဂလိပ်မူရင်းကိုသာ အတည်ယူပါ။

# အင်ဂျင်နီယာဆိုင်ရာ စံနှုန်းများ

BigTech+ Organization အောက်မှ repository များအားလုံးအတွက် ချမှတ်ထားတဲ့ guideline စံချိန်စံညွှန်းများ ဖြစ်ပါတယ်။ Repository များတွင် သီးခြား `CONTRIBUTING.md` ချမှတ်ထားခြင်းမရှိပါက ယခု guideline ကိုသာ အသုံးပြုရပါမယ်။

## Tooling

Developer များအားလုံးသည် repository အသစ်ဆောက်ခြင်းနှင့် ပုံမှန် GitHub workflow များအတွက် `gh` ကို အသုံးပြုကြရပါမည်။ [GitHub CLI](https://cli.github.com/) (`gh`) ကို install လုပ်ပြီး authenticate လုပ်ပါ။

```bash
gh auth login

gh extension install thebigtechplus/gh-bootstrap-repo
gh bootstrap-repo <repo-name> --create
```

Repo အသစ်ဆောက်ရန် [docs/new-repo.my.md](docs/new-repo.my.md) ကို ဖတ်ပါ။

## AI-assisted development

BigTech+ developer များသည် AI tool များ (Claude, Codex, Cursor) ကို assistant အနေဖြင့်သာ အသုံးပြုပြီး တရားဝင် author (author of record) အဖြစ် အသုံးမပြုရပါ။

- အဓိက guideline — repository ရှိ `AGENTS.md` သည် agent များအတွက် အသုံးပြုရန် [scripts/templates/AGENTS.md](scripts/templates/AGENTS.md) မှ seed လုပ်ထားခြင်းဖြစ်ပါတယ်။
- Claude Code — repository ရှိ `CLAUDE.md` သည် `@AGENTS.md` ကိုသာ import လုပ်ရပါမယ်။ ထို့ကြောင့် agent instruction များကို `AGENTS.md` တွင်သာ ပြင်ဆင်ထည့်သွင်းပြီး အသုံးပြုရပါမယ်၊ `CLAUDE.md` ထဲတွင် instruction စည်းမျဉ်းများ ထည့်မရေးရပါ။
- AI အကူအညီဖြင့် ရေးသားထားသော code ပြောင်းလဲမှုအားလုံးကို review လုပ်ခြင်း၊ test လုပ်ခြင်း၊ merge လုပ်ခြင်းများအတွက် သင်ကိုယ်တိုင်တာဝန်ယူရပါမယ်။

## ကျင့်ဝတ် (Conduct)

[Code of Conduct](CODE_OF_CONDUCT.my.md) ကို လိုက်နာရပါမယ်။ တစ်စုံတစ်ရာ စိုးရိမ်စရာရှိပါက [conduct@bigtechplus.io](mailto:conduct@bigtechplus.io) သို့ တင်ပြနိုင်ပါတယ်။

## အကူအညီနှင့် လုံခြုံရေး

[SUPPORT.my.md](SUPPORT.my.md) ကို ဖတ်ပါ။ လုံခြုံရေးနှင့်သက်ဆိုင်တဲ့ ပြဿနာများကို [SECURITY.my.md](SECURITY.my.md) အတိုင်း တင်ပြပါ — ပုံမှန် issue အဖြစ် မတင်ပါနှင့်။

## Branching

1. `main` မှ branch ခွဲပါ။
2. Branch များကို `type/issue-number-brief-description` ပုံစံနှင့်သာ အမည်ပေးရပါမယ် (ဥပမာ — `feat/12-add-login` သို့မဟုတ် `fix/34-header-alignment`)။
3. `main` သို့ pull request ဖွင့်ပါ။

## Commit message များ

[Conventional Commits](https://www.conventionalcommits.org/) ကို အသုံးပြုပါ —

| Prefix | အသုံးပြုရန် |
| --- | --- |
| `feat:` | feature အသစ် |
| `fix:` | bug ပြင်ဆင်မှု |
| `docs:` | documentation သီးသန့် |
| `style:` | behavior မပြောင်းလဲသော formatting |
| `refactor:` | fix သို့မဟုတ် feature မဟုတ်သော code ပြောင်းလဲမှု |
| `perf:` | performance မြှင့်တင်မှု |
| `test:` | test များ |
| `chore:` | ပြုပြင်ထိန်းသိမ်းမှု၊ tooling သို့မဟုတ် configuration |
| `ci:` | continuous integration |

## Pre-commit

Bootstrap ဖြင့် create လုပ်ထားသော repository များတွင် `.pre-commit-config.yaml` ပါဝင်ပြီးသား ဖြစ်ပါတယ်။ Repo clone လုပ်ပြီးလျှင် hook များကို တစ်ကြိမ် install လုပ်ပေးပါ —

```bash
pip install pre-commit

pre-commit install
pre-commit run --all-files   # optional first run
```

Hook များတွင် whitespace နှင့် EOF ပြင်ဆင်မှု၊ YAML စစ်ဆေးမှု၊ merge conflict၊ ဖိုင်အရွယ်အစားကြီးများ၊ private key များ၊ [Conventional Commits](https://www.conventionalcommits.org/) (commitizen)၊ shellcheck၊ markdownlint နှင့် gitleaks တို့ ပါဝင်ပါတယ်။

လိုအပ်ပါက repository အတွင်း language-specific hook များ ထည့်သုံးရပါမယ်။ မှတ်တမ်းတင်ပြုစုထားသော အကြောင်းပြချက် documentation မရှိဘဲ `--no-verify` ဖြင့် hook များကို မကျော်လွှားရပါ။

## Pull request များ

1. issue ရှိပါက pull request ကို issue နှင့် ချိတ်ဆက်ပါ။
2. pull request template ကို ပြည့်စုံစွာ ဖြည့်ပါ။
3. [admins](https://github.com/orgs/thebigtechplus/teams/admins) team မှ အနည်းဆုံး တစ်ဦးထံ review တောင်းပါ။
4. လိုအပ်တဲ့ check များ အောင်မြင်ပြီးဆုံးကြောင်း သေချာအောင် လုပ်ပေးပါ။
5. အောက်ပါ [merge guideline များ](#merging) အတိုင်း merge လုပ်ပါ။

Repository များတွင် source code နှင့် ပတ်သတ်သော အရာအားလုံးကို တာဝန်ယူဖြေရှင်းမယ့် `CODEOWNERS` ဖိုင် ပါဝင်သင့်သည် (ဤ repository ၏ `CODEOWNERS` သည် အခြား repo များသို့ သက်ရောက်ခြင်း မရှိပါ)။

## Merging

- **Squash merge သာ အသုံးပြုပါမယ်။** Merge commit နှင့် rebase merge များကို bootstrap တွင် တစ်ခါတည်း ပိတ်ထားပါတယ်။
- **Pull request ခေါင်းစဉ်သည်** `main` **branch ပေါ်ရှိ commit များဖြစ်လာမှာပါ၊** ဒါကြောင့် PR ခေါင်းစဉ်များသည် [Conventional Commits](https://www.conventionalcommits.org/) ပုံစံအတိုင်း ဖြစ်ရမည် (ဥပမာ — `feat: add login flow`)။ Merge မအတည်ပြုမီ squash commit body ကို ရှင်းလင်းပါ — PR တွင် ပါဝင်သော commit များအတိုင်းမဟုတ်ဘဲ အကျဉ်းချုပ် Summary အနေဖြင့်သာ merge လုပ်ပါ။
- **အောက်ပါအချက်အားလုံး ပြည့်စုံမှသာ merge လုပ်ပါ —**
  1. [admins](https://github.com/orgs/thebigtechplus/teams/admins) team မှ approval အနည်းဆုံး တစ်ခု။
  2. လိုအပ်သော check အားလုံး အောင်မြင်ပြီးမြောက်မှု။
  3. review conversation အားလုံး ဆွေးနွေးတိုင်ပင်ပြီးစီးမှု။
- **Approval ရပြီးနောက် author (developer) ကိုယ်တိုင် merge လုပ်နိုင်ပါတယ်။** အချိန်ကြာမြင့်စွာ ပစ်ထားခံရသော သို့မဟုတ် အချိန်မီလုပ်ဆောင်ရန် အရေးကြီးသော PR များကို admin များက author ကိုယ်စား merge လုပ်နိုင်ပါတယ်။
- **Review မရှိဘဲ ကိုယ့် PR ကို ကိုယ်တိုင် merge မလုပ်ပါနှင့်။** Repository တစ်ခု၏ တစ်ဦးတည်းသော maintainer ဖြစ်ပါက changes များသည် အန္တရာယ်ရှိနိုင်တဲ့အတွက် review ကို စောင့်ပါ။ သေးငယ်သော ပြောင်းလဲမှုများ (docs၊ typo) အတွက် ကိုယ်ပိုင်ဆုံးဖြတ်ချက်ဖြင့် merge လုပ်နိုင်ပြီး PR ထဲတွင် ထည့်ရေးဖော်ပြပေးရပါမယ်။
- Merge လုပ်ပြီးသည်နှင့် branch များကို auto ဖျက်ပါတယ်။ Merge လုပ်ပြီးသား branch ကို ပြန်မသုံးပါနှင့် — `main` မှ branch အသစ် စခွဲပါ။
- PR များကို သေးငယ်ပြီး တိကျသော ရည်ရွယ်ချက်ရှိပါစေ။ Feature အကြီးစားများ implement လုပ်သည်ဖြစ်စေ PR များကို သီးခြားစီ merge လုပ်နိုင်သော PR အစဉ်လိုက်အဖြစ် ခွဲထုတ်ပေးပါ။

## License

Repository အသစ်များသည် bootstrap မှ default အနေဖြင့် proprietary `LICENSE` (all rights reserved) ကို အသုံးပြုပါတယ်။ Repository တစ်ခုကို သဘောတူညီချက်ဖြင့် ရည်ရွယ်ချက်ရှိရှိ open source လုပ်မှသာ License ကို အစားထိုးရပါမယ်။
