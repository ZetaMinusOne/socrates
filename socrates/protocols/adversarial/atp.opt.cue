package atp

#Protocol: {
	name:        "Analogy Transfer Protocol"
	version:     "0.1.0"
	description: "Cross-domain structural transfer validation. Survivors carry acknowledged divergences."
}

#SourceConstruct: {
	name:             string
	domain:           string
	formal_statement: string  // the formalization in the source domain
	invariants:       [...string] // what the source formalization guarantees
}

#TargetDomain: {
	name:                string
	description:         string
	canonical_constructs: [...string] // already-canonicalized constructs in this domain
}

#Phase1: {
	source_construct:       #SourceConstruct
	target_domain:          #TargetDomain
	claimed_correspondence: string // the structural similarity being claimed
	motivation:             string // why this transfer would be useful
}

#StructuralMapping: {
	source_element:     string
	target_element:     string
	alignment_argument: string
	mapping_kind:       "direct" | "adjusted" | "partial"
	if mapping_kind == "adjusted" || mapping_kind == "partial" {
		adjustment_description: string
	}
}

#CorrespondenceCandidate: {
	id:          string
	description: string
	mappings:    [...#StructuralMapping]
	mappings:    [_, ...] // at least one mapping required

	// Does this candidate claim all source invariants transfer?
	invariants_transfer: bool
	if !invariants_transfer {
		non_transferring_invariants: [...string]
		non_transfer_argument:       string
	}

	// Domain-specific properties this candidate claims to gain.
	domain_specific_gains: [...string]
}

#Phase2: {
	candidates: [...#CorrespondenceCandidate]
	candidates: [_, ...]
}

#TransferRebuttal: {
	kind:     "refutation" | "scope_narrowing"
	argument: string
	valid:    bool
	limitation_description?: string // required if scope_narrowing
}

#DisanalogyCE: {
	id:               string
	target_candidate: string
	target_mapping?:  string // which mapping is challenged, if specific
	witness:          string // the case where the analogy breaks
	minimal:          bool & true
	rebuttal?:        #TransferRebuttal
}

#DomainMismatch: {
	id:               string
	target_candidate: string
	missing_property: string // the property the target domain lacks
	argument:         string // why this property is required for the transfer
	// Domain mismatch rebuttals must be refutations only.
	rebuttal?: {
		argument: string
		valid:    bool
	}
}

#ScopeChallenge: {
	id:               string
	target_candidate: string
	restricted_scope: string // the subset where the transfer holds
	argument:         string // why the transfer fails outside this scope
	rebuttal?:        #TransferRebuttal
}

#Phase3: {
	disanalogy_counterexamples: [...#DisanalogyCE]
	domain_mismatches:          [...#DomainMismatch]
	scope_challenges:           [...#ScopeChallenge]
}

#EliminationReason:
	"disanalogy_ce_unrebutted"   |
	"domain_mismatch_unrebutted" |
	"scope_challenge_unrebutted"

#EliminatedTransfer: {
	candidate_id: string
	reason:       #EliminationReason
	source_id:    string
}

#SurvivorTransfer: {
	candidate_id:     string
	scope_narrowings: [...string] // from scope_narrowing rebuttals; become acknowledged divergences
}

#Derived: {
	eliminated: [...#EliminatedTransfer]
	survivors:  [...#SurvivorTransfer]
}

#Phase3b: {
	triggered:  bool
	diagnosis:  "correspondence_too_strong" | "candidates_too_weak" | "transfer_not_viable"
	resolution: "revise_correspondence" | "revise_candidates" | "close_as_rejected"
	notes:      string
}

#Phase4: {
	multiple_survivors: bool
	if multiple_survivors {
		selected:        string // candidate id
		selection_basis: string
		alternatives_rejected: [...{
			candidate_id: string
			reason:       string
		}]
	}
	final_candidate: string
}

#TransferObligation: {
	property:  string // which invariant or property must be preserved
	argument:  string // why it holds in the target domain
	satisfied: bool
	if !satisfied {
		blocker: string
	}
}

#Phase5: {
	obligations:   [...#TransferObligation]
	all_satisfied: bool
}

#ValidatedTransfer: {
	source_construct:            string
	target_domain:               string
	adopted_correspondence:      string // description of the validated mapping
	transferred_formalization:   string // the formalization as instantiated in target domain
	acknowledged_divergences:    [...string] // from scope narrowings; places where transfer is limited
	preserved_invariants:        [...string]
	non_transferred_invariants:  [...string]
}

#RejectionRecord: {
	reason:              string
	strongest_challenge: string // the challenge that prevented transfer
	what_would_help:     string // what revision might enable future transfer
}

#Phase6: {
	validated_transfer?: #ValidatedTransfer
	rejection_record?:   #RejectionRecord
}

#Outcome: "validated" | "rejected" | "open"

#ATPInstance: {
	protocol: #Protocol
	version:  string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3

	derived: #Derived

	phase3b?: #Phase3b

	phase4?: #Phase4 // only if len(derived.survivors) > 1

	phase5:  #Phase5
	phase6?: #Phase6 // only if phase5.all_satisfied == true

	outcome:       #Outcome
	outcome_notes: string
}
