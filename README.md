# Context Anchoring Slash Commands

Martin Fowler의 [Context Anchoring](https://martinfowler.com/articles/reduce-friction-ai/context-anchoring.html) 패턴을 Claude Code 슬래시 커맨드로 구현한 것입니다.

## 설치

### 개인용 (모든 프로젝트에서 사용)
```bash
mkdir -p ~/.claude/commands
cp anchor.md ~/.claude/commands/
cp anchor-init.md ~/.claude/commands/
cp anchor-graduate.md ~/.claude/commands/
```

### 프로젝트용 (해당 프로젝트에서만 사용 + git으로 팀 공유)
```bash
mkdir -p .claude/commands
cp anchor.md .claude/commands/
cp anchor-init.md .claude/commands/
cp anchor-graduate.md .claude/commands/
```

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
