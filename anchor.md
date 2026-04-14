---
description: Save current session decisions and state to the feature context document
allowed-tools: Read, Write, Bash(date:*), Bash(ls:*), Bash(cat:*)
---

# /anchor — Context Anchoring

세션에서 내린 결정들을 로컬 feature 문서에 저장합니다.

## 작동 방식

1. **현재 대화 분석**: 이번 세션에서 내린 결정, 거절한 대안, 새로 생긴 제약, 해결된/미해결 질문을 파악합니다.

2. **기존 문서 확인**: `FEATURE_CONTEXT.md` 파일이 있으면 읽어서 현재 상태를 파악합니다.

3. **문서 업데이트**: 아래 형식으로 문서를 생성하거나 업데이트합니다.

## 문서 형식

```markdown
# Feature: [기능명]
_마지막 업데이트: [날짜]_

## Decisions
| 결정 | 이유 | 거절한 대안 |
|------|------|------------|
| ... | ... | ... |

## Constraints
- ...

## Open Questions
- [ ] 미해결 질문
- [x] 해결된 질문 (해결 방법: ...)

## State
- [x] 완료된 작업
- [ ] 다음 세션에서 할 작업

## Session Log
### [날짜]
- 이번 세션에서 한 주요 작업 요약
```

## 실행 지침

1. `FEATURE_CONTEXT.md`가 존재하는지 확인합니다.
2. 이번 대화에서 새로 결정된 것들을 Decisions 테이블에 추가합니다.
3. 새로운 제약사항이 생겼으면 Constraints에 추가합니다.
4. Open Questions를 최신 상태로 업데이트합니다 (해결된 건 [x], 새로 생긴 건 [ ]).
5. State 체크리스트를 현재 진행 상황에 맞게 업데이트합니다.
6. Session Log에 오늘 날짜와 이번 세션 요약을 추가합니다.
7. 파일을 저장하고 저장된 내용을 간략히 보고합니다.

**중요**: 결정의 *이유*와 *거절한 대안*을 반드시 기록합니다. "무엇을 했는가"보다 "왜 했는가"가 더 중요합니다.
