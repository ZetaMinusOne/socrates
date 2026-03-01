package cdp

#Protocol: {
	name:        "Construct Decomposition Protocol"
	version:     "0.1.1"
	description: "Incoherence-driven construct splitting. Parts must be more coherent than the whole."
}

#Construct: {
	name:        string
	description: string
	// The CFFP instance id that diagnosed this construct as incoherent, if any.
	// May be empty if decomposition was initiated directly.
	triggered_by?: string
}

#InvariantConflict: {
	invariant_a:   string // invariant id or description
	invariant_b:   string // invariant id or description
	demonstration: string // why no single formalism can satisfy both
}

#BehavioralPartition: {
	set_a: {
		description: string // what cases fall here
		behavior:    string // how the construct behaves in these cases
	}
	set_b: {
		description: string
		behavior:    string
	}
	incompatibility: string // why no single rule covers both behaviors
}

// A composition failure that only manifests in certain contexts,
// suggesting the construct behaves as different things in different roles.
#ContextualCompositionFailure: {
	context_a: {
		description:  string
		composes_with: string // what it successfully composes with here
	}
	context_b: {
		description:   string
		fails_with:    string // what it fails to compose with here
		failure_reason: string
	}
	implication: string // why this suggests two distinct constructs
}

#IncoherenceEvidence: {
	invariant_conflicts:           [...#InvariantConflict]
	behavioral_partitions:         [...#BehavioralPartition]
	contextual_composition_failures: [...#ContextualCompositionFailure]

	// At least one evidence item required across all three lists.
	// Enforced by protocol evaluator — CUE cannot express cross-list minimums directly.
	evidence_summary: string // evaluator's synthesis of why this construct is incoherent
}

#Phase1: {
	evidence: #IncoherenceEvidence
}

#Part: {
	name:        string
	description: string

	// The criterion that determines membership in this part.
	// Must be precise enough that a given case can be unambiguously assigned.
	boundary_criterion: string

	// Invariants this part claims to satisfy.
	// These become the Phase 1 invariants of the subsequent CFFP run for this part.
	claimed_invariants: [...{
		id:          string
		description: string
		class:       "termination" | "determinism" | "decidability" | "soundness" |
		             "completeness" | "composability" | "analyzability"
	}]
	claimed_invariants: [_, ...] // at least one required

	// Known limitations of this part — cases it explicitly does not cover.
	// These must not overlap with what sibling parts cover.
	explicit_exclusions: [...string]
}

#RecompositionArgument: {
	// Argument that the union of all parts covers the original construct's intended scope.
	coverage: string
	// Argument that no case belongs to more than one part.
	non_overlap: string
	evidence_mapping: string
}

#NaturalnessArgument: {
	argument: string // why this boundary is the *right* boundary, not just a valid one
	// What alternative boundaries were considered and rejected, and why.
	alternatives_considered: [...{
		boundary:       string
		rejection_reason: string
	}]
}

#SplitCandidate: {
	id:    string
	parts: [...#Part]
	parts: [_, _, ...] // at least two parts required

	recomposition: #RecompositionArgument
	naturalness:   #NaturalnessArgument

	// Anticipated failure modes of this split — ways the boundary might
	// turn out to be wrong or the parts might fail their subsequent CFFP runs.
	anticipated_failures: [...{
		description: string
		severity:    "fatal" | "degraded" | "ergonomic"
	}]
}

#Phase2: {
	candidates: [...#SplitCandidate]
	candidates: [_, ...] // at least one required
}

#BoundaryRebuttal: {
	kind:     "refutation" | "scope_narrowing"
	argument: string
	valid:    bool
	limitation_description?: string // required if kind is "scope_narrowing"
}

#BoundaryCounterexample: {
	id:               string
	target_candidate: string
	target_part?:     string // which part's boundary is challenged, if specific
	witness:          string // the case that cannot be unambiguously assigned
	violation:        "overlap" | "coverage_gap"
	minimal:          bool & true
	rebuttal?:        #BoundaryRebuttal
}

#RecompositionChallenge: {
	id:               string
	target_candidate: string
	challenges:       "coverage" | "non_overlap"
	argument:         string // demonstration that the recomposition argument fails
	// No rebuttal with scope narrowing permitted here.
	rebuttal?: {
		argument: string // must be a refutation, not a retreat
		valid:    bool
	}
}

#NaturalnessChallenge: {
	id:               string
	target_candidate: string
	alternative_boundary: string // the boundary being proposed as superior
	argument:         string     // why this boundary is strictly preferable
	rebuttal?: {
		argument: string // defense of the original boundary
		valid:    bool
	}
}

#CompositionFailure: {
	target_candidate: string
	target_part:      string // which part fails composition
	conflicts_with:   string // already-canonicalized construct
	violates:         string // invariant id or description
	description:      string
	// Not rebuttable.
}

#Phase3: {
	boundary_counterexamples:  [...#BoundaryCounterexample]
	recomposition_challenges:  [...#RecompositionChallenge]
	naturalness_challenges:    [...#NaturalnessChallenge]
	composition_failures:      [...#CompositionFailure]
}

#EliminationReason:
	"boundary_counterexample_unrebutted" |
	"recomposition_challenge_unrefuted"  |
	"composition_failure"                |
	"naturalness_dominated"

#EliminatedSplit: {
	candidate_id: string
	reason:       #EliminationReason
	source_id:    string
}

#SurvivorSplit: {
	candidate_id:     string
	scope_narrowings: [...string] // from scope-narrowing boundary rebuttals
	naturalness_limitations: [...string] // from unrebutted naturalness challenges with no dominating alternative
}

#Derived: {
	eliminated: [...#EliminatedSplit]
	survivors:  [...#SurvivorSplit]
}

#Phase3b: {
	triggered:  bool
	diagnosis:  "evidence_insufficient" | "candidates_too_weak" | "construct_not_decomposable"
	resolution: "revise_evidence" | "revise_candidates" | "close_as_unified"
	// "close_as_unified" — the incoherence evidence did not survive pressure;
	//   the construct may be coherent after all. Return to CFFP.
	notes:      string
	max_revisions: uint // terminate and set outcome "open" if exceeded
}

#SplitSelection: {
	selected:         string // candidate id
	selection_basis:  string // explicit reasoning against the criteria above
	alternatives_rejected: [...{
		candidate_id: string
		reason:       string
	}]
}

#Phase4: {
	multiple_survivors: bool
	if multiple_survivors {
		selection: #SplitSelection
	}
	final_candidate: string // id of the split proceeding to Phase 5
}

#PartReadiness: {
	part_name:              string
	boundary_precise:       bool
	invariants_consistent:  bool
	composition_clear:      bool
	recomposition_survived: bool
	ready:                  bool // conjunction of above; evaluator sets this explicitly
	if !ready {
		blocking_issues: [...string]
	}
}

#Phase5: {
	readiness: [...#PartReadiness]
	all_ready: bool // must be true to proceed to Phase 6
}

#AuthorizedPart: {
	name:               string
	boundary_criterion: string
	seed_invariants: [...{
		id:          string
		description: string
		class:       "termination" | "determinism" | "decidability" | "soundness" |
		             "completeness" | "composability" | "analyzability"
	}]
	acknowledged_limitations: [...string]
	depends_on: [...string] // already-canonicalized constructs this part composes with
}

#RecompositionProof: {
	coverage_argument:   string
	non_overlap_argument: string
	// Joint invariant: both CFFP runs must preserve this.
	joint_invariant:     string
}

#Phase6: {
	authorized_parts:    [...#AuthorizedPart]
	authorized_parts:    [_, _, ...] // at least two
	recomposition_proof: #RecompositionProof
	// Instructions for the subsequent CFFP runs.
	cffp_instructions:   string
}

#Outcome: "split" | "unified" | "open"

#CDPInstance: {
	protocol:  #Protocol
	construct: #Construct
	version:   string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3

	derived: #Derived

	phase3b?: #Phase3b

	phase4?: #Phase4 // only if len(derived.survivors) > 1

	phase5: #Phase5
	phase6?: #Phase6 // only if phase5.all_ready == true

	outcome:       #Outcome
	outcome_notes: string
}
