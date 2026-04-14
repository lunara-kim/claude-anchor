---
description: Graduate key decisions from FEATURE_CONTEXT.md into formal ADRs in docs/adr/
allowed-tools: Read, Write, Bash(date:*), Bash(ls:*), Bash(mkdir:*), Bash(find:*)
---

# /anchor-graduate — Feature Context → ADR 승격

피처가 완료됐을 때, `FEATURE_CONTEXT.md`의 핵심 결정들을 `docs/adr/`에 정식 ADR(Architecture Decision Record)로 저장합니다.

글에서 언급한 원칙: "significant decisions graduate to formal ADRs. For teams not yet using ADRs, this is a natural entry point."

## 실행 지침

1. **FEATURE_CONTEXT.md 읽기**
   현재 디렉토리의 `FEATURE_CONTEXT.md`를 읽습니다. 없으면 사용자에게 알립니다.

2. **기존 ADR 번호 확인**
   `docs/adr/` 디렉토리가 있으면 기존 파일 목록을 확인해서 다음 번호를 결정합니다.
   없으면 `docs/adr/` 디렉토리를 생성하고 0001부터 시작합니다.

3. **승격할 결정 선별**
   Decisions 테이블에서 아래 기준으로 ADR로 만들 가치가 있는 결정을 고릅니다:
   - 아키텍처나 기술 선택에 영향을 주는 결정
   - 나중에 다시 논의될 가능성이 있는 결정
   - 거절한 대안이 있어서 이유가 중요한 결정

   단순한 구현 세부사항(변수명, 파일 구조 등)은 ADR로 만들지 않습니다.

4. **결정마다 ADR 파일 생성**
   선별된 결정 각각에 대해 아래 형식으로 파일을 생성합니다:

   파일명: `docs/adr/NNNN-[결정을-요약한-kebab-case].md`

   ```markdown
   # ADR NNNN: [결정 제목]

   Date: [날짜]
   Status: Accepted
   Feature: [FEATURE_CONTEXT.md의 기능명]

   ## Context

   [이 결정이 필요했던 배경과 상황. FEATURE_CONTEXT.md의 Constraints와 맥락을 활용.]

   ## Decision

   [무엇을 결정했는가. 구체적으로.]

   ## Rationale

   [왜 이 결정을 내렸는가. FEATURE_CONTEXT.md의 "이유" 컬럼을 확장.]

   ## Rejected Alternatives

   [고려했다가 거절한 대안들과 거절 이유. FEATURE_CONTEXT.md의 "거절한 대안" 컬럼을 확장.]

   ## Consequences

   [이 결정으로 인한 결과. 긍정적인 것과 부정적인 것 모두.]
   ```

5. **FEATURE_CONTEXT.md 완료 처리**
   ADR 생성 후 `FEATURE_CONTEXT.md` 상단에 완료 표시를 추가합니다:

   ```markdown
   > ✅ 완료됨 — [날짜]
   > 핵심 결정은 docs/adr/NNNN-*.md 로 승격되었습니다.
   ```

6. **결과 보고**
   생성된 ADR 파일 목록과 경로를 사용자에게 보고합니다.
   FEATURE_CONTEXT.md를 이제 삭제하거나 보관할 수 있음을 안내합니다.

## 참고

모든 결정을 ADR로 만들 필요는 없습니다. feature 문서는 일기, ADR은 교훈입니다.
"결정의 이유"가 미래에도 가치 있을 것 같은 것만 승격하세요.
