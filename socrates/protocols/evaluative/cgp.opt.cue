package cgp

#Protocol: {
	name:        "Canonical Governance Protocol"
	version:     "0.1.0"
	description: "Adjudicates fitness-for-purpose of canonical forms. Handles revision through deprecation."
}

#CanonicalReference: {
	construct:                string
	source_run_id:            string
	formal_statement:         string
	evaluation_def:           string
	satisfies:                [...string]
	acknowledged_limitations: [...string]
	canonicalized_at:         string // ISO 8601
}

#RevisionProposal: {
	id:          string
	proposed_by: string | *"unattributed"
	description: string
	changes: {
		formal_statement?:   string
		evaluation_def?:     string
		add_invariants?:     [...string]
		remove_invariants?:  [...string]
		add_limitations?:    [...string]
		remove_limitations?: [...string]
	}
	motivation:          string
	claims_non_breaking: bool
}

#EvidenceKind:
	"practical_failure"    |
	"invariant_erosion"    |
	"superior_alternative" |
	"design_space_shift"   |
	"implementation_burden"

#DeprecationEvidence: {
	kind:             #EvidenceKind
	description:      string
	severity:         "compelling" | "suggestive" | "weak"
	failure_cases?:   [...string]
	limitation_refs?: [...string]
}

#DeprecationCase: {
	submitted_by: string | *"unattributed"
	summary:      string
	evidence:     [...#DeprecationEvidence]
	evidence:     [_, ...]
}

#GovernanceCase: {
	kind: "revision" | "deprecation" | "combined"

	if kind == "revision" {
		revision: #RevisionProposal
	}

	if kind == "deprecation" {
		deprecation: #DeprecationCase
	}

	if kind == "combined" {
		// Combined: deprecating the current canonical form and proposing a replacement.
		deprecation:  #DeprecationCase
		revision:     #RevisionProposal // the proposed replacement/successor
		relationship: string            // how the revision relates to the deprecation
	}
}

#Phase1: {
	canonical: #CanonicalReference
	case:      #GovernanceCase
}

#PreservationVerdict: "preserved" | "broken" | "weakened" | "indeterminate"

#InvariantPreservation: {
	invariant_id: string
	verdict:      #PreservationVerdict
	rationale:    string
	if verdict == "broken" || verdict == "weakened" {
		intentional:    bool
		justification?: string // required if intentional
	}
}

#InvariantErosion: {
	invariant_id:     string
	eroded:           bool
	erosion_argument: string
	if eroded {
		severity: "fatal" | "degraded"
	}
}

#Phase2: {
	// Populated when case.kind == "revision" or "combined"
	preservation_checks?: [...#InvariantPreservation]

	// Populated when case.kind == "deprecation" or "combined"
	erosion_assessments?: [...#InvariantErosion]

	// Overall invariant health verdict for this phase.
	invariant_health:          "sound" | "degraded" | "broken" | "indeterminate"
	invariant_health_argument: string
}

#SuccessorReadiness: {
	evaluated:             bool
	has_canonical_form:    bool
	canonical_run_id?:     string
	covers_all_invariants: bool
	invariant_gaps:        [...string]
	migration_path_exists: bool
	migration_description?: string
	ready:                 bool
}

#Phase3: {
	// Is there a declared successor in the governance case?
	successor_proposed: bool
	if successor_proposed {
		successor_ref: string // reference to the proposed successor/revision
		readiness:     #SuccessorReadiness
	}
	if !successor_proposed {
		// Is there an undeclared alternative that should be considered?
		alternative_exists: bool
		if alternative_exists {
			alternative_description: string
			alternative_readiness:   #SuccessorReadiness
		}
	}
	assessment_notes: string
}

#MigrationBurden: "trivial" | "moderate" | "significant" | "unknown"

#Dependent: {
	id:          string
	kind:        "canonical_construct" | "implementation" | "protocol_run" | "other"
	description: string
}

#DependentImpact: {
	dependent_id: string
	breaking:     bool
	burden:       #MigrationBurden
	rationale:    string
	if breaking {
		severity:    "fatal" | "degraded"
		description: string
		blocker:     bool
	}
}

#Phase4: {
	known_dependents:     [...#Dependent]
	impact_assessments:   [...#DependentImpact]
	total_burden:         #MigrationBurden
	blocked_dependents:   [...string] // dependent_ids with blocker: true
	incomplete_landscape: bool
	if incomplete_landscape {
		unknown_dependents: string
	}
}

#Verdict: "admissible_revision" | "inadmissible" | "deprecated" | "conditional_retention" | "deferred"

#DeprecationNotice: {
	construct:          string
	reason:             string
	successor?:         string
	migration_guidance: string
	effective_at:       string // ISO 8601
}

#RevisedCanonical: {
	formal_statement:         string
	evaluation_def:           string
	satisfies:                [...string]
	acknowledged_limitations: [...string]
}

#ConditionalRetention: {
	conditions:            [...string]
	re_evaluation_trigger: string
	provisional_expiry:    string
}

#Phase5: {
	verdict:   #Verdict
	rationale: string

	if verdict == "inadmissible" {
		blocking_reasons: [...string]
	}
	if verdict == "deprecated" {
		deprecation_notice: #DeprecationNotice
	}
	if verdict == "admissible_revision" {
		revised_canonical: #RevisedCanonical
	}
	if verdict == "conditional_retention" {
		conditional_retention: #ConditionalRetention
	}
	if verdict == "deferred" {
		required_before_ruling: [...string]
	}
}

#Outcome: "admissible_revision" | "inadmissible" | "deprecated" | "conditional_retention" | "deferred"

#CGPInstance: {
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
