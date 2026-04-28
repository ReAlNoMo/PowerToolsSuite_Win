# 🔒 Security Policy

PowerTools Suite includes modules that interact with:

* Windows Registry
* Security settings
* Performance configurations
* Network settings
* Administrative system functions

Because of the elevated nature of certain modules, responsible security reporting is highly encouraged.

---

## 🛡️ Supported Versions

Only the latest stable release receives active security updates and vulnerability patches.

| Version | Supported |
| ------- | --------- |
| 1.2.x   | ✅ Yes     |
| 1.1.x   | ❌ No      |
| 1.0.x   | ❌ No      |
| < 1.0   | ❌ No      |

---

## 🚨 Reporting a Vulnerability

If you discover a security vulnerability, privilege escalation issue, unsafe script behavior, or dangerous configuration flaw, please report it responsibly.

### 📩 Preferred Reporting Method

Please open a **private security advisory** via GitHub Security Advisories if available.

### Alternative:

If private advisories are unavailable, open a GitHub issue labeled:

```txt
[SECURITY]
```

---

## 📋 Please Include:

* A clear description of the vulnerability
* Affected module(s)
* Steps to reproduce
* Potential impact
* Screenshots / logs if applicable
* Suggested mitigation (optional)

---

## ⏱️ Response Expectations

### Initial Response:

* Within **3–7 business days**

### Status Updates:

* Provided when investigation progresses

### Resolution:

* Critical vulnerabilities prioritized
* Security fixes released in supported versions only

---

## 🔐 Responsible Disclosure Guidelines

Please do **NOT**:

* Publicly disclose vulnerabilities before review
* Share weaponized exploit code without warning
* Abuse vulnerabilities on third-party systems
* Submit malicious pull requests

---

## ✔ Accepted Vulnerabilities May Include:

* Privilege escalation
* Unsafe registry modifications
* Remote code execution risks
* Script injection
* Dangerous installer behavior
* Security bypasses
* Unintended persistence mechanisms
* Broken sandbox integrations

---

## ❌ Out of Scope

The following are generally not considered security vulnerabilities:

* UI bugs
* Cosmetic issues
* Minor documentation errors
* Non-security performance regressions
* Unsupported third-party software issues

---

## ⚠️ Important Notice

Certain modules intentionally perform advanced system modifications for optimization or diagnostics.

These are **not vulnerabilities** when functioning as documented, but unintended unsafe behavior should always be reported.

---

## 📜 MIT License Reminder

This project is provided under the MIT License without warranty; however, security concerns are taken seriously and best-effort remediation will be provided for supported versions.

---

## 👤 Maintainer

**ReAlNoMo**
PowerTools Suite Security Team

---

> 🛡️ Security is a shared responsibility.
> Please report issues responsibly to help improve PowerTools Suite for everyone.
