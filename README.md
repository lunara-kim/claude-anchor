# Context Anchoring Slash Commands

Martin Fowler의 [Context Anchoring](https://martinfowler.com/articles/reduce-friction-ai/context-anchoring.html) 패턴을 Claude Code 슬래시 커맨드로 구현한 것입니다.

## 설치

### 원라이너 (권장)

```bash
curl -fsSL https://raw.githubusercontent.com/lunara-kim/claude-anchor/main/install.sh | bash
```

스크립트가 하는 일:
- `~/.claude/commands/`에 anchor 커맨드 3개 복사
- `~/.claude/settings.json`에 Stop hook 병합 (기존 설정 보존, 백업 생성)
- 이미 설치되어 있으면 hook을 깔끔히 교체 (중복 방지)

> `jq`가 필요합니다 (settings.json 안전 병합용). 없으면 스크립트가 안내합니다.

### 수동 설치

```bash
git clone https://github.com/lunara-kim/claude-anchor
cd claude-anchor
./install.sh
```

또는 완전 수동:
```bash
mkdir -p ~/.claude/commands
cp anchor.md anchor-init.md anchor-graduate.md ~/.claude/commands/
# settings.json은 기존 파일과 수동 병합
```

### 프로젝트용 (팀 공유)

```bash
mkdir -p .claude/commands
cp anchor.md anchor-init.md anchor-graduate.md .claude/commands/
cp settings.json .claude/settings.json
```

## 업데이트

설치 방식에 따라:

**원라이너로 설치한 경우** — 같은 커맨드 재실행
```bash
curl -fsSL https://raw.githubusercontent.com/lunara-kim/claude-anchor/main/install.sh | bash
```
기존 hook은 마커로 식별해 교체하므로 중복되지 않습니다. settings.json은 실행 시마다 타임스탬프 백업됩니다.

**git clone으로 설치한 경우**
```bash
cd claude-anchor && git pull && ./install.sh
```

**symlink로 설치한 경우** (고급) — 소스를 한 번만 clone하고 심볼릭 링크
```bash
git clone https://github.com/lunara-kim/claude-anchor ~/src/claude-anchor
ln -sf ~/src/claude-anchor/anchor.md        ~/.claude/commands/
ln -sf ~/src/claude-anchor/anchor-init.md   ~/.claude/commands/
ln -sf ~/src/claude-anchor/anchor-graduate.md ~/.claude/commands/
# 업데이트는 git pull만 하면 자동 반영
cd ~/src/claude-anchor && git pull
```

## 자동 Anchor (기본 동작)

사용자가 커맨드 실행을 까먹어도 컨텍스트가 날아가지 않도록, `settings.json`에 **Stop hook**이 포함되어 있습니다.

Claude 응답이 끝날 때마다 현재 디렉토리를 체크해서 Claude에게 조건부 지시를 주입합니다:

- **`FEATURE_CONTEXT.md`가 있으면** → "의미 있는 변경이 있었으면 `/anchor` 실행하라"
- **없으면** → "이번 세션이 substantive한 피처 작업이었으면 `/anchor-init` 실행하라"

Claude가 세션 내용을 보고 판단하기 때문에, 빠른 질문이나 단순 수정에는 반응하지 않고, 실제 피처 작업일 때만 자동으로 생성/업데이트됩니다.

즉, **피처 시작부터 종료까지 수동 개입 없이 자동으로 anchor가 관리됩니다.** 물론 수동으로도 언제든 `/anchor-init`, `/anchor`, `/anchor-graduate` 실행 가능합니다.

자동화를 원치 않는 경우 `settings.json`의 `Stop` hook 부분만 제거하세요.

## 전체 워크플로

```
피처 시작
    ↓
/anchor-init [기능명]
    → FEATURE_CONTEXT.md 생성
    ↓
세션 작업 ... 세션 끝
    ↓
/anchor
    → FEATURE_CONTEXT.md 업데이트 (결정/이유/거절한 대안 기록)
    ↓
(반복: 다음 세션 시작 시 FEATURE_CONTEXT.md 공유 → 30초 컨텍스트 복구)
    ↓
피처 완료
    ↓
/anchor-graduate
    → 핵심 결정들을 docs/adr/NNNN-*.md 로 승격
    → FEATURE_CONTEXT.md 완료 처리 후 삭제 가능
```

## 커맨드 설명

| 커맨드 | 시점 | 역할 |
|--------|------|------|
| `/anchor-init [기능명]` | 피처 시작 | `FEATURE_CONTEXT.md` 생성 |
| `/anchor` | 세션 종료 시 | 결정사항 문서에 기록 |
| `/anchor-graduate` | 피처 완료 시 | 핵심 결정을 `docs/adr/`에 ADR로 승격 |

## 왜 필요한가?

AI 세션은 기본적으로 휘발성입니다. 대화가 길어질수록 초반 결정의 *이유*가 먼저 사라집니다.
이 커맨드들은 "무엇을 했는가"뿐 아니라 "왜 했는가", "무엇을 거절했는가"를 로컬에 영구 보존합니다.

- `FEATURE_CONTEXT.md` — 작업 일지. 피처가 살아있는 동안 계속 업데이트.
- `docs/adr/` — 교훈. 미래에도 가치 있는 결정만 선별해서 영구 보존.

**리트머스 테스트**: 지금 세션을 닫고 새로 시작해도 불안하지 않으면, 컨텍스트가 잘 고정된 것입니다.
