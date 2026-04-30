# 🤝 Contributing to PowerTools Suite

First off — thank you for your interest in contributing to **PowerTools Suite**.

PowerTools Suite is a unified WPF-based PowerShell utility platform focused on:

* Windows utilities
* Security tools
* Performance optimization
* Diagnostics
* Download automation
* Modular extensibility

We welcome contributions that improve functionality, security, performance, documentation, and user experience.

---

# 📋 Contribution Types

You can contribute through:

* 🐞 Bug reports
* ✨ Feature requests
* 🔧 Bug fixes
* 🧩 New modules
* 📚 Documentation improvements
* 🎨 UI/UX enhancements
* 🔒 Security improvements
* ⚡ Performance optimizations

---

# ⚠️ Important Project Standards

Because this project includes modules that may alter:

* Windows Registry
* Security settings
* Performance configurations
* Administrative functions

All contributions must prioritize:

## Required:

* Stability
* Security
* Transparency
* Logging
* Error handling
* User safety

---

# 🧠 Development Guidelines

## ✔ General Standards

* Use clear, maintainable PowerShell code
* Follow `Verb-Noun` naming conventions
* Use inline comments only when necessary
* Maintain modular structure
* Preserve compatibility with:

  * PowerShell 7+
  * Windows 10
  * Windows 11
* Maintain WPF compatibility
* Support Light/Dark theme integration
* Use `$Global:PTS_Brush` dynamic theme system
* Ensure responsive UI behavior

---

## ✔ Mandatory Best Practices

### All modules should:

* Use `Try/Catch` for critical operations
* Include timestamped logging
* Provide user-facing status updates
* Use background processing for long-running tasks
* Use `ConcurrentQueue` or thread-safe communication where needed
* Avoid blocking UI threads
* Support cancellation where applicable
* Clearly indicate Admin requirements
* Backup critical system changes where possible

---

# 📁 Module Structure

Custom modules should follow:

```powershell id="rk3h8w"
Register-PowerToolsModule `
    -Id "custom-id" `
    -Name "Custom Module" `
    -Description "What it does" `
    -Category "Category" `
    -RequiresAdmin $false `
    -Show { }
```

---

## 📄 Naming Convention

```txt id="l9hlyh"
modules/NN-ModuleName.ps1
```

Example:

```txt id="2wqb6i"
modules/08-SystemAudit.ps1
```

---

# 🌙 Theme Compatibility

All UI modules must:

* Support Light + Dark mode
* Use dynamic brushes
* Avoid hardcoded colors
* Maintain visual consistency
* Preserve accessibility/readability

---

# 🔒 Security Requirements

Contributions must NOT:

* Introduce malicious code
* Add hidden persistence
* Use unsafe remote execution
* Bypass user consent
* Modify critical settings without warning
* Remove safety confirmations
* Introduce telemetry without disclosure

---

# 🧪 Testing Expectations

Before submitting:

## Minimum:

* Test on supported Windows versions
* Verify PowerShell 7 compatibility
* Confirm Light/Dark mode support
* Validate Admin/Non-Admin flows
* Test logging output
* Ensure no UI freezes
* Verify safe rollback where applicable

---

# 🌿 Branching Workflow (Recommended)

## Suggested naming:

* `feature/module-name`
* `fix/bug-description`
* `security/issue-name`
* `docs/update-name`

---

# 🔄 Pull Request Process

## Before submitting:

* Fork repository
* Create dedicated branch
* Test thoroughly
* Update documentation if needed
* Include screenshots for UI changes
* Clearly explain:

  * What changed
  * Why it changed
  * Potential risks
  * Required permissions

---

## PR Requirements:

* Focused scope
* Clean commit history
* No unrelated changes
* Security-conscious design
* Theme compatibility maintained

---

# 🐞 Reporting Bugs

Please include:

* Module affected
* Windows version
* PowerShell version
* Steps to reproduce
* Logs/screenshots
* Expected behavior
* Actual behavior
* Admin status

---

# 💡 Feature Requests

For new ideas:

* Describe use case
* Explain value
* Identify risks
* Suggest implementation approach if possible

---

# 📜 Licensing

By contributing, you agree that your contributions will be licensed under the project's **MIT License**.

---

# ⚖️ Disclaimer

Due to the advanced nature of certain modules:

* Contributors are responsible for testing their changes
* High-risk modules may require additional review
* Unsafe or harmful contributions will be rejected

---

# 📩 Communication

Primary communication channels:

* GitHub Issues
* Pull Requests
* Security Advisories (for vulnerabilities)

---

# 🙏 Final Notes

PowerTools Suite prioritizes:

* User safety
* Transparency
* Performance
* Professionalism
* Maintainability

We appreciate contributions that align with these principles.

---

> ⚡ Build responsibly.
> 🔒 Secure by design.
> 🧩 Modular by nature.

---

**ReAlNoMo**
PowerTools Suite • CONTRIBUTING Guide
