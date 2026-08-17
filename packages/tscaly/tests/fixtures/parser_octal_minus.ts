// The legacy-octal report reaches BACK over a preceding minus, because the
// message suggests `-0o…` as the replacement and the sign is part of what has
// to be rewritten. The scanner can ask because `state.token` is still the
// PREVIOUS token while it scans.
-0777;
