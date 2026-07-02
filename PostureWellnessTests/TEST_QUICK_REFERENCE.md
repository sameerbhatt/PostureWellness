# Quick Test Reference Card

## Critical Path (5 minutes)
1. Launch app → Grant permissions
2. Wait 60s → First capture succeeds
3. Menu → Analyze Now → Works
4. Menu → Take a Break Now → Window opens
5. Settings → Opens and is functional

## Common Issues Checklist
- [ ] Camera permission granted
- [ ] Good lighting conditions
- [ ] Upper body visible in frame
- [ ] No other apps using camera
- [ ] Notifications permission granted

## Performance Targets
- CPU idle: < 1%
- Memory: < 200MB
- Capture time: < 5s
- Battery: < 5% per hour

## Quick Smoke Test (Per Build)
Run TC-001, 004, 005, 007, 013, 019, 030, 036, 043, 046

## Reporting Bugs
Use template in MANUAL_TEST_CASES.md
Include: TC number, steps, expected, actual, logs
