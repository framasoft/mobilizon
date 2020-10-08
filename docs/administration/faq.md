---
title: FAQ
---

# FAQ

## Should I have a big server to run Mobilizon?


Not really. Being written in Elixir, Mobilizon doesn't need much resources once it's running. If you plan to open your instance to the public, plan in advance higher values for the following given requirements.

!!! note
    If you plan to self-host a address/geocoding server as well, [the requirements are quite on another level](./configure/geocoders.md).

<dl>
    <dt>CPU</dt>
    <dd><b>One should be enough</b>
    <p>Depending on your number of users and instances you federate with, extra CPUs will be helpful.</p>
    </dd>

    <dt>RAM</dt>
    <dd>
        <b>512MB should be enough for Mobilizon, Nginx and PostgreSQL</b>
        <p>Mobilizon will use at least around ~256MB and PostgreSQL and nginx can use ~20MB. Extra memory can improve tasks like compiling and building dependencies.</p>
    </dd>

    <dt>Storage</dt>
    <dd><b>Depends how many users and events you have</b>
        <p>A little space will be needed for Mobilizon and it's dependencies (damn you <code>node_modules</code>) themselves. Otherwise, storage usage will grow mostly with user's profile pics and pictures associated to events. Also the PostgreSQL database can start to weigh a bit after a while, depending on how many events you create and how many other instances you follow.</p>
    </dd>

    <dt>Bandwidth</dt>
    <dd>Any bandwidth will do, but higher numbers will improve the experience for users and will help federation.</dd>
</dl>