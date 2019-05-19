[Mobilizon](https://joinmobilizon.org) takes security, privacy and user control seriously, and we want to put them front and centre of our project.

This document outlines security procedures and general policies for the Mobilizon project.
Framasoft, the Mobilizon maintainer team and community take all security bugs in Mobilizon seriously. Thank you for improving the security of Mobilizon. We appreciate your efforts and responsible disclosure and will make every effort to acknowledge your contributions.

### Goals

* Mobilizon users can understand the distinctions between public data and private data/metadata on Mobilizon.

* Users always know where their private data/metadata resides, who has access to it, and are able to access, export, and delete it.

* Protect private user data/metadata, not just from hackers but also (as much as is possible) from other users, instance admins, community moderators, and external applications.

* Secure from malicious creation, alteration or deletion of public data.

* GDPR compliance.

Framasoft is both a developer of open-source/free/libre self-hosted software, and a service provider with users in the European Union. As a result, we are putting user privacy, data sovereignty, and GDPR compliance into our security plans, including asking both the Framasoft community and outside hackers to review our approaches and implementations.

### Challenges

[Mobilizon](https://joinmobilizon.org) will be challenging to keep secure, as it is:

* open source, both back-end and front-end

* self-hosted by diverse organisations and individuals

* federated (data is transmitted between different hosted instances)

This means there are more attack surfaces compared to typical proprietary, centralised platforms, but also means that hackers and even users can review every part of Mobilizon and make sure that it works as expected. This should result in more secure software, and higher trust in the application and its ecosystem.

### Responsible Disclosure Guidelines

We are committed to working with security researchers to verify, reproduce, and respond to legitimate reported vulnerabilities. You can help us by following these simple guidelines:

* Alert us about the vulnerability as soon as you become aware of it by emailing the lead maintainer at tcit+mobilizon@framasoft.org.
* Provide details needed to reproduce and validate the vulnerability and a Proof of Concept (PoC) as soon as possible
* Act in good faith to avoid privacy violations, destruction of data, and interruption or degradation of services
* Do not access or modify users’ private data, without explicit permission of the owner. Only interact with your own accounts or test accounts for security research purposes;
* Contact Framasoft or a maintainer of the Mobilizon project (or the instance admin) immediately if you do inadvertently encounter user data. Do not view, alter, save, store, transfer, or otherwise access the data, and immediately purge any local information upon reporting the vulnerability;
* The lead maintainer will acknowledge your email within 48 hours, and will send a more detailed response within 48 hours indicating the next steps in handling your report. After the initial reply to your report, the security team will endeavor to keep you informed of the progress towards a fix and full announcement, and may ask for additional information or guidance.
* Give us time to confirm, determine the affected versions and prepare fixes to correct the issue before disclosing it to other parties (if after waiting a reasonable amount of time, we are clearly unable or unwilling to do anything about it, please do hold us accountable!)
* Please test against a local instance of the software, and refrain from running any Denial of Service or automated testing tools against Framasoft's (and our partners') infrastructure

Note : Please report security bugs in third-party modules to the person or team maintaining the module.

### Comments on this Policy

If you have suggestions on how this process could be improved please submit a pull request.
