# V0.0.2 QA checklist

- [ ] Verify GameGuardian Lua runtime and syntax compatibility
- [ ] Confirm current V0.0.1 startup and menus on Android
- [ ] Check device authorization after reboot
- [ ] Test failed network request and invalid payload responses
- [ ] Confirm Arabic/English menu strings and selection mapping
- [ ] Confirm settings persist after restart
- [ ] Test backup/export and restore with malformed inputs
- [ ] Verify update manifest, checksum, consent, and rollback
- [ ] Test error logs do not leak personal identifiers
- [ ] Verify all original modules before release

Do not mark any test passed without executing it.
