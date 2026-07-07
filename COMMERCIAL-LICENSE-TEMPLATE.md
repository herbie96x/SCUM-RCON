# COMMERCIAL LICENSE AGREEMENT — SCUM-RCON

> Template. Fill placeholders `{{...}}` before signing. Governs commercial use of
> SCUM-RCON, overriding the non-commercial restriction in `LICENSE` for the named
> Licensee only.

**Licensor:** herbie (SKRYPT) — copyright holder of SCUM-RCON
**Licensee:** {{LICENSEE_NAME}} ({{LICENSEE_PROJECT}}, {{LICENSEE_CONTACT}})
**Effective date:** {{EFFECTIVE_DATE}}

---

## 1. Definitions
- **Software** — the SCUM-RCON mod component authored by the Licensor (the RCON
  communication/automation bridge). Excludes third-party components listed in §8.
- **Platform** — the Licensee's product {{LICENSEE_PROJECT}} that integrates the
  Software.
- **Paying Customer** — an end user on a paid plan of the Platform whose plan
  depends on the Software (see §3).
- **Reporting Period** — {{REPORTING_PERIOD}} (e.g. monthly / quarterly).

## 2. Grant of License
The Licensor grants the Licensee a non-exclusive, non-transferable, worldwide
license to integrate and use the Software within the Platform for commercial
purposes, for the term in §6. This overrides the "Commercial Use" restriction of
the standard `LICENSE` for the Licensee only.

## 3. Scope
The license covers use of the Software as a communication/automation layer inside
the Platform — including in-game item delivery, shop fulfilment, kits, event
rewards, and similar server-automation features. It does **not** grant rights to:
- resell, redistribute, or sublicense the Software as a standalone product;
- repackage the Software as the Licensee's own product;
- remove or alter Licensor copyright notices.

## 4. Fees
- **Royalty:** {{ROYALTY_PCT}}% of the Platform's revenue from Paying Customers on
  Software-dependent plans, per Reporting Period.
  - Reference (at time of drafting): {{PLAN_A_NAME}} {{PLAN_A_PRICE}} → {{PLAN_A_ROYALTY}} per Paying Customer/month;
  {{PLAN_B_NAME}} {{PLAN_B_PRICE}} → {{PLAN_B_ROYALTY}} per Paying Customer/month.
- **Free / non-paying users are excluded.**
- **Minimum annual floor:** {{FLOOR_AMOUNT}} per year, regardless of Paying
  Customer count, payable {{FLOOR_SCHEDULE}}.
- **Currency:** {{CURRENCY}}. **Payment method:** {{PAYMENT_METHOD}}.

## 5. Reporting & Payment
- Each Reporting Period the Licensee reports the number of Paying Customers on
  Software-dependent plans and the resulting royalty due.
- Figures are provided on a good-faith self-report basis; the Licensor may request
  supporting figures from the Platform's billing/subscription system for review.
- Royalties due within {{PAYMENT_DAYS}} days of each Reporting Period.
- **Audit right:** the Licensor (or an independent auditor engaged by the Licensor)
  may, at most once per calendar year and on reasonable notice, review the billing
  and subscription records underlying the reported figures. If an audit reveals
  revenue was under-reported by more than 5%, the Licensee bears the full cost of
  the audit in addition to paying the shortfall.

## 6. Term & Revisit
- **Term:** starts on the Effective date, runs for {{TERM_LENGTH}}, auto-renews
  unless terminated per §7.
- **Revisit clause:** once the Platform reaches {{REVISIT_THRESHOLD}} (e.g. 100+
  Paying Customers, or {{REVISIT_REVENUE}} monthly revenue), both parties review
  and, if needed, renegotiate the fees in good faith.

## 7. Termination
- Either party may terminate with {{NOTICE_PERIOD}} written notice.
- The Licensor may terminate immediately on material breach (non-payment,
  redistribution, misrepresentation of Paying Customer counts) not cured within
  {{CURE_PERIOD}} of written notice.
- **Transition period:** on ordinary termination (i.e. not for material breach),
  the Licensee may continue using the Software for {{TRANSITION_PERIOD}} (e.g. 30
  days) solely to migrate or wind down its customers cleanly, with royalties still
  due for that period. On termination for material breach, use ceases immediately.
- After the transition period (or immediately, on material breach) the Licensee
  ceases all use of the Software in the Platform.

## 8. Third-Party Components
This Agreement covers only the Software authored by the Licensor. Any bundled
third-party components (e.g. `rcon_console` — MIT, © FMJ / scumsaecke.de; UE4SS —
MIT; mcrcon — zlib) remain under their own licenses and are **not** granted or
restricted by this Agreement. The Licensee is responsible for complying with
those licenses independently.
> Note: if the Licensee integrates only the Software's RCON bridge (its own client
> UI), the FMJ `rcon_console` component is not involved.

## 9. Support & Maintenance
This license grants **no right to technical support, bug fixes, or compatibility
updates** for future SCUM or UE4SS versions. SCUM-RCON is a game mod: a game or
engine update may break it at any time, and the Licensor gives no guarantee of
continued functionality. Any updates, fixes, or support the Licensor provides are
voluntary and create no obligation to provide further ones.

## 10. Confidentiality
Where the Licensee is given access to non-public internals of the Software —
source code, undocumented APIs, protocol details, build configuration — the
Licensee shall keep them strictly confidential, use them solely to integrate the
Software into the Platform, and not disclose, publish, or share them (in whole or
in part) with any third party. This obligation survives termination.

## 11. Ownership
Title and IP rights in the Software remain with the Licensor. The Software is
licensed, not sold.

## 12. Warranty & Liability
The Software is provided "as is", without warranty of any kind, to the fullest
extent permitted by applicable law. Subject to §12a, the Licensor is not liable
for damages arising from the Software or its use, including server crashes, data
loss, or game incompatibilities.

### 12a. Liability under German law
Where {{GOVERNING_LAW}} is German law, liability is governed as follows and the
blanket exclusion above applies only within these limits:
- The Licensor is liable without limitation for intent (Vorsatz) and gross
  negligence (grobe Fahrlässigkeit), and for injury to life, body, or health.
- For slight negligence (leichte Fahrlässigkeit), the Licensor is liable only for
  breach of a material contractual obligation (Kardinalpflicht), limited to
  foreseeable, contract-typical damage.
- Any liability beyond this is excluded. Liability under the Produkthaftungsgesetz
  remains unaffected.

## 13. Governing Law
{{GOVERNING_LAW}} (e.g. Germany). Disputes: {{DISPUTE_VENUE}}.

---

**Licensor:** ______________________  Date: __________

**Licensee:** ______________________  Date: __________

<!-- Placeholders to fill:
{{LICENSEE_NAME}} {{LICENSEE_PROJECT}} {{LICENSEE_CONTACT}} {{EFFECTIVE_DATE}}
{{REPORTING_PERIOD}} {{ROYALTY_PCT}} {{PLAN_A_NAME}} {{PLAN_A_PRICE}} {{PLAN_A_ROYALTY}}
{{PLAN_B_NAME}} {{PLAN_B_PRICE}} {{PLAN_B_ROYALTY}} {{FLOOR_AMOUNT}} {{FLOOR_SCHEDULE}}
{{CURRENCY}} {{PAYMENT_METHOD}} {{PAYMENT_DAYS}} {{TERM_LENGTH}} {{TRANSITION_PERIOD}}
{{REVISIT_THRESHOLD}} {{REVISIT_REVENUE}} {{NOTICE_PERIOD}} {{CURE_PERIOD}}
{{GOVERNING_LAW}} {{DISPUTE_VENUE}}
-->

