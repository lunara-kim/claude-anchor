---
description: Initialize a new feature context document for context anchoring
allowed-tools: Write, Bash(date:*), Bash(ls:*), Bash(mkdir:*)
---

# /anchor-init — Feature Context 초기화

새로운 기능 작업을 시작할 때 `FEATURE_CONTEXT.md`를 생성합니다.

## 실행 지침

$ARGUMENTS 값이 있으면 그것을 기능명으로 사용합니다. 없으면 사용자에게 기능명을 물어봅니다.

현재 날짜를 가져온 뒤, 아래 형식으로 `FEATURE_CONTEXT.md`를 현재 디렉토리에 생성합니다:

```markdown
# Feature: [기능명]
_생성일: [날짜] | 마지막 업데이트: [날짜]_

> 이 파일은 Context Anchoring 문서입니다.
> 새 세션 시작 시 이 파일을 Claude에게 공유하세요.
> `/anchor` 커맨드로 세션이 끝날 때마다 업데이트하세요.
> 피처 완료 시 `/anchor-graduate`로 핵심 결정을 ADR로 승격하세요.

## Decisions
| 결정 | 이유 | 거절한 대안 |
|------|------|------------|
| (아직 없음) | | |

## Constraints
- (아직 없음)

## Open Questions
- [ ] (아직 없음)

## State
- [ ] 초기 설계
- [ ] 구현
- [ ] 테스트
- [ ] 완료

## Session Log
### [날짜]
- Feature 컨텍스트 문서 초기화
```

파일 생성 후, 사용자에게 다음을 안내합니다:
- 파일이 생성된 위치
- 세션 끝날 때 `/anchor`로 업데이트하는 방법
- 다음 세션 시작 시 이 파일을 Claude에게 붙여넣거나 공유하면 됨
- 피처 완료 시 `/anchor-graduate`로 핵심 결정을 `docs/adr/`에 ADR로 승격할 수 있음
