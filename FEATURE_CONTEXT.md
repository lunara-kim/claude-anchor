# Feature: claude-anchor — Context Anchoring 슬래시 커맨드 도구
_생성일: 2026-04-15 | 마지막 업데이트: 2026-04-15_

> 이 파일은 Context Anchoring 문서입니다.
> 새 세션 시작 시 이 파일을 Claude에게 공유하세요.
> `/anchor` 커맨드로 세션이 끝날 때마다 업데이트하세요.
> 피처 완료 시 `/anchor-graduate`로 핵심 결정을 ADR로 승격하세요.

## Decisions

| 결정 | 이유 | 거절한 대안 |
|------|------|------------|
| `/anchor-init`을 `/anchor`에 통합 (self-bootstrap) | 별도 init 커맨드를 두는 건 사용 마찰만 늘림. `/anchor`가 파일 없으면 생성, 있으면 업데이트하면 사용자는 "세션 끝나면 `/anchor`" 한 동작만 기억하면 됨. 실제 meeting-scribe 세션에서 `/anchor-init` 누락으로 auto-trigger 실패한 것이 증거. | `/anchor-init` 유지 (과잉 분리) / 두 커맨드 별칭화 (해결 안 됨, 여전히 두 개 존재) |
| Stop hook을 `echo` stdout 대신 `{"decision":"block","reason":"..."}` JSON 응답으로 구현 | Claude Code 공식 스펙상 Stop hook stdout은 디버그 로그로만 가고 Claude에게 전달되지 않음. `decision:block`은 `reason`을 Claude에게 피드백으로 주입하는 유일한 공식 메커니즘. | stdout echo (동작 안 함, 실제 검증됨) / SessionEnd hook (세션 종료 후 실행이라 의미 없음) / UserPromptSubmit hook (세션 시작에만 트리거, 종료 자동화 불가) |
| 무한 루프 방지는 Claude Code 제공 `stop_hook_active` 플래그로 | 공식적으로 보장되는 escape hatch. hook이 받는 stdin JSON에 포함됨. 자체 세션 마커 파일보다 단순하고 신뢰 가능. | 세션 ID 기반 `/tmp/marker-{session_id}` 파일 (복잡, OS별 경로 이슈, 정리 필요) / 1회 카운터 (상태 관리 부담) |
| Hook 로직을 `anchor-hook.py` 별도 스크립트로 분리 | JSON 파싱과 분기 로직을 bash 인라인으로 쓰면 escaping 지옥. settings.json의 command 필드는 스크립트를 호출하는 한 줄로만. | 거대한 bash 인라인 (가독성 최악, 유지보수 불가) / Node.js 스크립트 (claude-anchor 쓸 사용자에게 Node 요구 과함) |
| 설치 시 settings.json 병합을 `jq` 선호 + `python3`/`python` fallback | `jq`는 Windows Git Bash 기본 설치 안 됨. Python은 Windows/macOS/Linux 어디든 거의 있음. 자동 package install은 sudo/신뢰 문제로 하지 않음. | jq 강제 요구 (Windows 사용자 barrier) / jq 자동 설치 (OS별 복잡, 권한 이슈) / 수동 병합만 안내 (UX 최악) |
| 구 anchor-init 버전에서 업그레이드 시 `anchor-init.md` 자동 삭제 | 남아있으면 `/anchor-init` 커맨드가 여전히 노출되어 사용자 혼란. 사라진 커맨드를 이름으로 명시해 clean 마이그레이션. | 그대로 두고 README 경고 (사용자 실수 유발) / deprecation 메시지 stub 파일 (dead code) |
| Stop hook의 "substantive work" 정의를 **넓게** (testing/logging/deploy/tooling 포함) | meeting-scribe에서 테스트 스위트 도입이 "feature work 아님"으로 읽혀 auto-init이 안 발동한 실패 사례 있음. 설계 선택이 개입된 작업은 전부 포함. | 좁은 정의 "feature implementation만" (실제 실패 경험으로 기각) / 모든 작업 포함 (빠른 질문에도 발동해 노이즈) |

## Constraints

- Stop hook은 Claude Code 공식 스펙에 제약됨 — `decision:block` 외에는 Claude에게 추가 행동 유도 불가
- `jq`는 Windows Git Bash 기본 미설치 — Python fallback 필수
- `anchor-hook.py`는 Python 3.6+ 문법만 사용 (widely available)
- Hook 경로는 `$HOME/.claude/anchor-hook.py` 고정 — 다른 위치 지원하면 settings.json 동기화 복잡
- Slash command 파일은 `.claude/commands/*.md` 위치 규약 고정 (Claude Code 스펙)

## Open Questions

- [ ] Graduate 자동화 가능성 — 피처 "완료" 시점은 사람만 아는 도메인 지식이라 현재 수동. 커밋 메시지나 PR merge 같은 이벤트로 유도할 수 있을지?
- [ ] Project-local settings.json 배포 패턴 — `.claude/settings.json`을 git commit 하는 팀 대상 설치 플로우 개선 여지
- [ ] Hook이 메시지를 띄우는 빈도 조절 — 현재는 세션당 1회 확정 발동. 사용자가 "빠른 질문"이라 판단하면 자동 skip되도록 프롬프트 개선 여지
- [ ] `/anchor`가 자동 발동될 때 기능명 추론 — 현재는 Claude가 대화 맥락에서 추론. 부정확하면 파일명/섹션이 어색해짐
- [ ] macOS/Linux 환경 실제 테스트 — 현재 Windows Git Bash에서만 검증. `$HOME` 확장, 경로 구분자, Python 명령어 이름 등 이슈 가능성

## State

- [x] `/anchor`, `/anchor-graduate` 커맨드 작성 및 self-bootstrap 로직
- [x] Stop hook을 `decision:block` JSON 응답 기반으로 재구현
- [x] `anchor-hook.py` Python 스크립트 분리
- [x] `stop_hook_active` 플래그로 루프 방지
- [x] `install.sh` (jq + Python fallback, 레거시 정리)
- [x] Windows Git Bash에서 설치/실행 검증
- [x] README 전체 재작성 (설치/업데이트/워크플로)
- [ ] macOS/Linux 환경 실제 테스트
- [ ] awesome-claude-code 리포지토리 PR 제출
- [ ] 실제 프로젝트(meeting-scribe 등)에서 auto-trigger 장기 관찰

## Session Log

### 2026-04-14
- 초기 구상: Martin Fowler Context Anchoring 글 읽고 Claude Code 슬래시 커맨드로 구현
- `/anchor-init`, `/anchor`, `/anchor-graduate` 3개 커맨드 작성
- GitHub 레포 `lunara-kim/claude-anchor` 생성, 초기 push
- Stop hook 추가 (초기 echo 방식)
- `install.sh` 작성 + Python fallback 추가 (jq 부재 환경 대응)
- meeting-scribe 실전 사용: 테스트 스위트 도입 시 auto-init이 발동 안 하는 gap 발견

### 2026-04-15
- 구조적 로깅 도입 세션에서 auto-trigger 재차 실패 관찰
- 원인 조사: Claude Code 공식 문서 확인 결과 Stop hook stdout은 Claude에게 전달되지 않음이 확정
- `decision:block` + `reason` JSON 응답으로 메커니즘 전환 → Claude가 실제로 reason 읽고 행동
- `stop_hook_active` 플래그로 무한 루프 방지
- `anchor-hook.py` 별도 스크립트로 분리 (bash 인라인 JSON 조작 회피)
- `/anchor-init`을 `/anchor`에 통합 (self-bootstrap) — 사용 마찰 제거
- Stop hook "substantive work" 정의 확대 (testing/logging/deploy/tooling 포함)
- 실제 hook 발동 검증 완료 (이 세션에서 `Stop hook feedback` 수신 확인)
- 이 도구 자체에 대한 `FEATURE_CONTEXT.md` 작성 (meta-anchoring)
