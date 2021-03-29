## runit config files

These are the config files to run _Mobilizon_ under `runit` supervisor.

The `user` directory contains the configs for running it completely under a
user, with full supervisory control. It requires the system to start
`runsvdir` in user mode so the dæmon can be handled as the user as

  - `sv start ~/sv/mobilizon`
  - `sv stop ~/sv/mobilizon`

This method is good when you are not root, or it's not simple to switch.



The `system_wide` directory contains the config to administer by root user,
if you can access root easily.
