sys_is_root() { test $(id -u) -eq 0; }

sys_must_root() {
  sys_is_root || trap_fatal $? 'Must run as root!'
}
