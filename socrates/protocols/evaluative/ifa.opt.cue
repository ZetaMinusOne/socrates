package ifa

#Protocol: {
	name:        "Implementation Fidelity Audit"
	version:     "0.1.1"
	description: "Adjudicates whether an implementation faithfully realizes a canonical form."
}

#CanonicalReference: {
	construct:        string // name of the canonicalized construct
	source_run_id:    string // ARP record or CFFP run that produced this canonical form
	formal_statement: string // the canonical definition, verbatim
	evaluation_def:   string // operational semantics, verbatim
	satisfies:        [...string] // invariant ids the canonical form claims to satisfy
	acknowledged_limitations: [...string] // known scope exclusions
}

#ImplementationArtifact: {
	id:          string // identifier for this artifact (filename, commit hash, policy id, etc.)
	kind:        "code" | "policy" | "schema" | "document" | "system_behavior" | "other"
	description: string // what the implementation claims to do
	excerpt:     string // the relevant portion of the implementation being audited
}

#Phase1: {
	canonical:       #CanonicalReference
	implementation:  #ImplementationArtifact
}

#FidelityObligation: {
	id:          string // e.g. "FO1", "FO2"
	derived_from: string // invariant id or aspect of canonical form this comes from
	description: string // what the implementation must do to satisfy this
	// Is this obligation covered by the canonical form's acknowledged limitations?
	// If so, it may not apply to this implementation.
	excluded_by_limitation: bool | *false
	limitation_ref?: string // which acknowledged limitation excludes this, if applicable
}

#Phase2: {
	obligations: [...#FidelityObligation]
	obligations: [_, ...]
}

#ObligationVerdict: "satisfied" | "violated" | "indeterminate"

#DivergenceKind:
	"missing_behavior"    | // the implementation simply doesn't handle this case
	"incorrect_behavior"  | // the implementation handles it but produces the wrong result
	"scope_excess"        | // the implementation handles cases the canonical form excludes
	"evaluation_mismatch" | // the evaluation order or rule differs from the canonical def
	"invariant_violation"   // a claimed invariant is structurally broken

#DivergenceSeverity: "fatal" | "degraded" | "cosmetic"

#ObligationEvaluation: {
	obligation_id: string
	verdict:       #ObligationVerdict

	if verdict == "violated" {
		divergence_kind:     #DivergenceKind
		severity:            #DivergenceSeverity
		evidence:            string // what in the implementation demonstrates the violation
		fixable:             bool   // can the implementation be fixed, or does the canonical form need revision?
		if !fixable {
			canonical_gap: string // what the canonical form would need to specify differently
		}
	}

	if verdict == "indeterminate" {
		underspecification: string // what aspect of the canonical form is ambiguous
		required_protocol:  "CFFP" | "CBP" // which IAP would resolve the ambiguity
	}

	notes: string | *""
}

#Phase3: {
	evaluations: [...#ObligationEvaluation]
	evaluations: [_, ...]
}

#FidelityVerdict: "faithful" | "divergent" | "indeterminate"

#VerdictSummary: {
	verdict:           #FidelityVerdict
	satisfied_count:   int
	violated_count:    int
	indeterminate_count: int
	fatal_violations:  [...string] // obligation ids with severity "fatal"
	fixable_violations: [...string] // obligation ids where fixable: true
	canonical_gaps:    [...string] // obligation ids where fixable: false
}

#Phase4: {
	verdict_summary: #VerdictSummary
}

#RemediationTarget: "implementation" | "canonical_form" | "new_iap_run"

#RemediationItem: {
	obligation_id: string
	target:        #RemediationTarget
	description:   string
	if target == "new_iap_run" {
		protocol: "CFFP" | "CBP"
		rationale: string
	}
}

#Phase5: {
	items: [...#RemediationItem]
}

#Outcome: "faithful" | "divergent" | "indeterminate"

#IFAInstance: {
	protocol: #Protocol
	version:  string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3
	phase4: #Phase4
	phase5: #Phase5

	outcome:       #Outcome
	outcome_notes: string
}
