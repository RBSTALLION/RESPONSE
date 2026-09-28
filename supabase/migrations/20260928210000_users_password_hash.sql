-- Web logins (controller / admin / client portal) sign in with email + password.
-- Officers on the mobile app still use passcode_hash.
alter table users add column if not exists password_hash text;
