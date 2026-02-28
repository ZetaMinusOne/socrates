package cffp

#Protocol: {
	name:        "Constraint-First Formalization Protocol"
	version:     "0.2.1"
	description: "Invariant-driven semantic design. Candidates survive pressure or die."
}

#Construct: {
	name:        string
	description: string

	depends_on: [...string]
}

#Invariant: {
	id:          string // short identifier, e.g. "I1", "I2"
	description: string // precise enough that two independent agents agree on its meaning
	testable:    bool & true
	structural:  bool & true

	class: "termination" | "determinism" | "decidability" | "soundness" |
	       "completeness" | "composability" | "analyzability"
}

#Phase1: {
	invariants: [...#Invariant]
	invariants: [_, ...] // at least one required
}

#ProofSketch: {
	invariant_id: string
	argument:     string // informal but precise argument for why invariant holds
}

#FailureMode: {
	description: string // what breaks
	trigger:     string // the condition that causes it
	severity:    "fatal" | "degraded" | "ergonomic"
}

#Complexity: {
	time:   string // e.g. "O(n)", "O(n²)", "linear in stratum count"
	space:  string
	static: string // complexity of static analysis over this construct
}

#Candidate: {
	id:          string
	description: string

	formalism: {
		structure:       string // what the construct is, formally
		evaluation_rule: string // how it is evaluated
		resolution_rule: string // how conflicts/ambiguities resolve
	}

	// Explicit invariant satisfaction claims with proof sketches.
	// A claim without a proof sketch is inadmissible.
	claims: [...#ProofSketch]
	claims: [_, ...] // at least one required

	complexity: #Complexity
	failure_modes: [...#FailureMode]
}

#Phase2: {
	candidates: [...#Candidate]
	candidates: [_, ...] // at least one required
}

#Rebuttal: {
	argument: string // why the counterexample does not constitute a violation
	valid:    bool   // set by protocol evaluator

	kind: "refutation" | "scope_narrowing"

	// Required when kind is "scope_narrowing": what scope was excluded.
	// This text becomes an entry in canonical.acknowledged_limitations.
	limitation_description?: string

	// Required when valid is false: which invariant claim is considered falsified.
	// The candidate is eliminated unless it withdraws the claim entirely.
	falsified_claim?: string
}

#Counterexample: {
	id:               string
	target_candidate: string
	violates:         string // invariant id
	witness:          string // the minimal concrete case demonstrating violation
	minimal:          bool & true // must be explicitly asserted

	rebuttal?: #Rebuttal
}

#CompositionFailure: {
	target_candidate:      string
	conflicts_with:        string // name of already-canonicalized construct
	violates:              string // invariant id
	description:           string
	// No rebuttal field. Composition failures are not rebuttable.
}

#Phase3: {
	counterexamples:    [...#Counterexample]
	composition_failures: [...#CompositionFailure]
}

#EliminationReason: "counterexample_unrebutted" | "counterexample_invalid_rebuttal" | "composition_failure"

#Eliminated: {
	candidate_id: string
	reason:       #EliminationReason
	source_id:    string
}

#Survivor: {
	candidate_id: string
	scope_narrowings: [...string]
}

#Derived: {
	eliminated: [...#Eliminated]
	survivors:  [...#Survivor]
	// survivors must be non-empty to proceed past Phase 3.
	// If empty, phase3b is required.
}

#Phase3b: {
	triggered:  bool
	diagnosis:  "invariants_too_strong" | "candidates_too_weak" | "construct_incoherent"
	resolution: "revise_invariants" | "revise_candidates" | "reframe_and_close"
	notes:      string
}

#CollapseResult: {
	attempted: bool
	if attempted {
		succeeded: bool
		if succeeded {
			merged_candidate: #Candidate
			replaces: [...string] // ids of survivors that were merged
		}
		if !succeeded {
			reason:          string
			selected:        string // id of survivor selected for canonicalization
			selection_basis: string // rationale for selection
		}
	}
}

#StaticObligation: {
	property:  string // what is being proved
	argument:  string // informal proof or reduction argument
	provable:  bool   // evaluator's assessment
	// If not provable, canonicalization is blocked.
	if !provable {
		blocker: string // what would need to change to make it provable
	}
}

#Phase5: {
	obligations: [...#StaticObligation]
	// All obligations must have provable: true to proceed to Phase 6.
	all_provable: bool
}

#CanonicalForm: {
	construct:           string // name of the construct being canonicalized
	formal_statement:    string // the definition
	evaluation_def:      string // operational semantics
	satisfies:           [...string] // invariant ids
	acknowledged_limitations: [...string] // from scope-narrowing rebuttals, if any
}

#Phase6: {
	canonical: #CanonicalForm
}

#Outcome: "canonical" | "collapse" | "open"

#CFFPInstance: {
	protocol:  #Protocol
	construct: #Construct
	version:   string // e.g. "1.0", "1.1" — increments on Phase 3b restarts

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3

	// Explicitly populated after Phase 3. Required before Phase 4 can proceed.
	derived: #Derived

	phase3b?: #Phase3b   // only if derived.survivors is empty

	phase4?: #CollapseResult // only if len(derived.survivors) > 1
	phase5:  #Phase5
	phase6?: #Phase6         // only if phase5.all_provable == true

	outcome: #Outcome
	outcome_notes: string // evaluator's summary of why this outcome was reached
}
