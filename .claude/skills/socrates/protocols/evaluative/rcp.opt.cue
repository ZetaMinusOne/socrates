package rcp

#Protocol: {
	name:        "Reconciliation Protocol"
	version:     "0.1.1"
	description: "Output reconciliation. Establishes the relationship between independently produced protocol outputs. Does not re-run protocols or produce new canonical forms."
}

// ProtocolKind identifies which protocol produced a given output.
#ProtocolKind: "ADP" | "AAP" | "CBP" | "CDP" | "CFFP" | "HEP" | "RCP"

#InputRun: {
	id:       string // local identifier for this run within the RCP instance
	protocol: #ProtocolKind
	version:  string // version of the protocol that produced this output
	outcome:  string // the outcome declared by the run (e.g. "canonical", "mapped", "split")

	// What domain, construct, or question does this run cover?
	// Be precise. Vague scope declarations make conflict detection unreliable.
	scope: string

	primary_claims: [...string]

	// Assumptions this run makes that are not internally justified.
	// These are candidates for conflict with other runs' claims.
	external_assumptions: [...string]

	// Acknowledged limitations declared by this run.
	// Limitations are not conflicts — they are declared scope boundaries.
	acknowledged_limitations: [...string]

	// Reference to the original run artifact, if available.
	source?: string
}

#VocabularyAlignment: {
	term:  string
	kind:  "synonym" | "homonym" | "neologism"

	if kind == "synonym" {
		// Which runs use this term and what do they call it?
		variants: [...{
			run_id: string
			local_term: string
		}]
		// The canonical term for this RCP instance.
		canonical_term: string
		alignment_rationale: string
	}

	if kind == "homonym" {
		usages: [...{
			run_id:  string
			meaning: string
			scope:   string // the scope within which this meaning applies
		}]
		// Is this resolvable by scope qualification?
		scope_resolvable: bool
		if !scope_resolvable {
			// A CBP run is required before conflict detection can proceed
			// for claims that use this term.
			cbp_required: bool & true
			cbp_question: string // the question for the CBP run
		}
	}

	if kind == "neologism" {
		introduced_by: string // run_id
		definition:    string
	}
}

#Phase1: {
	alignments: [...#VocabularyAlignment]

	// Are any CBP runs required before conflict detection can proceed?
	cbp_blockers: [...string] // terms requiring CBP runs
	blocked: bool // true if any cbp_blockers exist

	// Evaluator's summary of the vocabulary landscape.
	vocabulary_summary: string
}

#ConflictClass:
	"vocabulary_conflict" |
	"scope_mismatch"      |
	"assumption_conflict" |
	"structural_conflict"

#Conflict: {
	id:    string
	class: #ConflictClass

	// Which runs are in conflict?
	run_a: string // run_id
	run_b: string // run_id

	// What specifically conflicts?
	claim_a:    string // the claim or assumption from run_a
	claim_b:    string // the claim or assumption from run_b

	// Why is this a conflict after vocabulary alignment?
	conflict_argument: string

	// Is this conflict potentially resolvable within RCP,
	// or does it require an upstream re-run?
	resolvable_within_rcp: bool
	if !resolvable_within_rcp {
		upstream_action: string // what re-run or revision is required
	}
}

#Phase2: {
	// Log of which run pairs were examined.
	examination_log: [...{
		run_a:   string
		run_b:   string
		examined: bool
		if !examined {
			skip_justification: string
		}
	}]

	conflicts: [...#Conflict]

	// Evaluator's summary of the conflict landscape.
	conflict_summary: string
}

#ResolutionMechanism: "scope_clarification" | "assumption_surfacing" | "vocabulary_resolution"

#ResolutionAttempt: {
	conflict_id: string
	mechanism:   #ResolutionMechanism
	argument:    string // the resolution argument

	succeeded: bool

	if succeeded {
		// What the resolution established.
		resolution_record: string

		if mechanism == "scope_clarification" {
			scope_boundaries: [...{
				run_id: string
				scope:  string
			}]
		}

		if mechanism == "assumption_surfacing" {
			surfaced_assumption: string
			assumption_holds:    bool
			if assumption_holds {
				// Conflict was apparent. Record assumption as now explicit.
				explicit_assumption: string
			}
		}
	}

	if !succeeded {
		// Conflict re-classified as structural. Carries to Phase 4.
		failure_reason: string
	}
}

#Phase3: {
	attempts: [...#ResolutionAttempt]

	// Conflicts that were not attempted (structural from Phase 2, or
	// blocked by vocabulary conflicts requiring CBP).
	not_attempted: [...{
		conflict_id: string
		reason:      string
	}]

	// Evaluator's summary of what was resolved and what remains.
	resolution_summary: string
}

#PairRelationship:
	"compatible"      |
	"reconciled"      |
	"conflicted"      |
	"incommensurable"

#RunPairRecord: {
	run_a:        string
	run_b:        string
	relationship: #PairRelationship

	if relationship == "compatible" {
		scope_boundaries: [...string]
		compatibility_argument: string
	}

	if relationship == "reconciled" {
		resolved_conflicts: [...string] // conflict ids
		resolution_records: [...string] // what each resolution established
	}

	if relationship == "conflicted" {
		unresolved_conflicts: [...string] // conflict ids
		upstream_actions:     [...string] // what must happen before these can be resolved
	}

	if relationship == "incommensurable" {
		incommensurability_argument: string // why comparison is not meaningful
		partial_commensurability?: string
	}
}

#JointlySupportedClaim: {
	claim:          string
	supporting_runs: [...string] // run_ids
	support_argument: string // why each run supports this claim
	// Is the support genuinely independent, or could the runs have
	// inherited this claim from a common source?
	independent:    bool
	if !independent {
		shared_source: string
	}
}

#ReconciliationMap: {
	pairs: [...#RunPairRecord]

	jointly_supported_claims: [...#JointlySupportedClaim]

	most_dangerous_conflict?:  string // conflict id; absent if no unresolved conflicts
	most_dangerous_argument?:  string

	// All upstream actions required before the run set can be treated as coherent.
	upstream_actions_required: [...{
		conflict_id:  string
		action:       string // what must happen
		protocol:     #ProtocolKind // which protocol to re-run
		input:        string // what the re-run's input should be
	}]

	// Overall assessment.
	overall_relationship: "compatible" | "reconciled" | "conflicted" | "incommensurable" | "mixed"
	// "mixed" — different pairs have different relationships.
	//           The overall assessment cannot be reduced to a single label.
	overall_argument: string
}

#Phase4: {
	reconciliation_map: #ReconciliationMap
}

#RCPRecord: {
	input_runs:     [...string] // run_ids
	total_conflicts: uint
	resolved_conflicts: uint
	unresolved_conflicts: uint
	jointly_supported_claims: uint

	// Plain-language summary of the reconciliation outcome.
	summary: string

	// What can safely be built on this run set as-is?
	// What cannot be built until upstream conflicts are resolved?
	safe_to_build:     string
	blocked_until:     string // what must be resolved first; "nothing" if no blockers
}

#Phase5: {
	record: #RCPRecord
}

#RCPOutcome: "compatible" | "reconciled" | "conflicted" | "incommensurable" | "mixed"

#RCPInstance: {
	protocol: #Protocol
	version:  string

	// The set of protocol runs being reconciled.
	// Minimum two required — reconciling a single run is not reconciliation.
	inputs: [...#InputRun]
	inputs: [_, _, ...]

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3
	phase4: #Phase4
	phase5: #Phase5

	outcome:       #RCPOutcome
	outcome_notes: string
}
