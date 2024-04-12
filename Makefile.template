
.PHONY: shell
shell:
	nix develop -f default.nix -j auto -i -k TERM -k PATH -k HOME -v shell

.PHONY: lock
lock:
	nix develop -f default.nix lock
