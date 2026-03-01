package hep

#Protocol: {
	name:        "Hypothesis Elimination Protocol"
	version:     "0.1.1"
	description: "Evidence-driven hypothesis elimination. Survivors are least-eliminated, not proven."
}

#Phenomenon: {
	description: string // what was observed
	context:     string // the system, environment, or conditions in which it occurred
	// Precise characterization of the observation.
	// Vague phenomena produce vague hypotheses. Be specific.
	observation: string

	// Is this phenomenon reproducible?
	reproducible: bool
	if !reproducible {
		// If not reproducible, note what this implies for experiment design.
		reproducibility_notes: string
	}
}

#ModeDeclaration: {
	bounded: bool

	// exhaustive may only be true in bounded mode.
	// An unbounded+exhaustive declaration is rejected by the protocol.
	exhaustive: bool

	// Structural constraint: unbounded mode cannot be exhaustive.
	// Enforced by protocol evaluator.
	if !bounded {
		exhaustive: false
	}

	exhaustiveness_argument?: string
	budget?: {
		max_hypotheses:  uint // maximum hypotheses permitted across all revision cycles
		max_experiments: uint // maximum experiments permitted
		// If either limit is exceeded, the run closes as "open" with
		// outcome_notes explaining what budget was exhausted.
	}
	// Required when bounded is false.
}

#Prediction: {
	id:          string
	description: string // what should be observable if this hypothesis is correct
	// Is this prediction discriminating — i.e., would its failure specifically
	// challenge this hypothesis rather than all hypotheses equally?
	discriminating: bool
	// What it would mean if this prediction fails.
	failure_implication: string
}

#Hypothesis: {
	id:          string
	description: string

	// The proposed causal mechanism.
	cause: string

	predictions: [...#Prediction]
	predictions: [_, ...] // at least one required
	prior_plausibility: "high" | "medium" | "low"
	plausibility_argument: string // why this prior is assigned

	// Known conditions under which this hypothesis cannot hold.
	// Declaring these upfront improves the quality of discriminating experiments.
	known_exclusions: [...string]
}

#Phase1: {
	hypotheses: [...#Hypothesis]
	hypotheses: [_, ...] // at least one required
	exhaustiveness_argument?: string
}

#EvidenceItem: {
	id:          string
	description: string
	source:      "existing" | "experimental"

	if source == "experimental" {
		experiment: {
			design:      string // how the experiment is conducted
			feasible:    bool
			if !feasible {
				feasibility_blocker: string
			}
			// In unbounded mode, cost must be declared.
			cost?: "negligible" | "moderate" | "high" | "prohibitive"
		}
		// Has the experiment been executed?
		executed: bool
		if executed {
			result: string // what was observed
		}
	}

	if source == "existing" {
		observation: string // what was observed
	}

	weight: "decisive" | "strong" | "weak"
}

// Assessment of a single evidence item against a single hypothesis.
#EvidenceAssessment: {
	evidence_id:   string
	hypothesis_id: string
	consistency:   "consistent" | "inconsistent" | "uninformative"
	argument:      string // why this assessment holds
}

#Phase2: {
	evidence:    [...#EvidenceItem]
	assessments: [...#EvidenceAssessment]
	// All evidence items must have assessments against all hypotheses.
	// Enforced by protocol evaluator.
}

#EvidenceRebuttal: {
	hypothesis_id: string
	evidence_id:   string
	kind:          "refutation" | "scope_narrowing" | "evidence_unreliability"
	argument:      string
	valid:         bool
	limitation_description?: string // required if kind is "scope_narrowing"
	// If evidence_unreliability: what makes the evidence unreliable.
	unreliability_argument?: string // required if kind is "evidence_unreliability"
}

// Accumulated weak pressure assessment.
#AccumulatedPressure: {
	hypothesis_id:      string
	evidence_ids:       [...string] // the weak inconsistencies being aggregated
	rises_to_strong:    bool
	argument:           string // why the accumulation does or does not rise to strong pressure
}

// Cross-hypothesis support record.
#CrossSupport: {
	supported_hypothesis:    string
	pressured_hypothesis:    string
	evidence_id:             string
	argument:                string // why this evidence relatively supports one over the other
}

#Phase3: {
	rebuttals:            [...#EvidenceRebuttal]
	accumulated_pressure: [...#AccumulatedPressure]
	cross_support:        [...#CrossSupport]
}

#EliminationReason:
	"decisive_inconsistency"       |
	"strong_inconsistency_unrebutted" |
	"accumulated_weak_pressure"

#EliminatedHypothesis: {
	hypothesis_id: string
	reason:        #EliminationReason
	// For decisive/strong inconsistency: the evidence item id.
	// For accumulated_weak_pressure: the id of the #AccumulatedPressure record in Phase3.
	source_id: string
}

#SurvivorHypothesis: {
	hypothesis_id:    string
	scope_narrowings: [...string] // from scope-narrowing rebuttals
	// Relative support: cross-support records that favor this hypothesis.
	relative_support: [...string] // evidence ids
	// Remaining pressure: weak inconsistencies not risen to strong level.
	remaining_pressure: [...string] // evidence ids
}

#Derived: {
	eliminated: [...#EliminatedHypothesis]
	survivors:  [...#SurvivorHypothesis]
}

#Phase3b: {
	triggered:  bool
	trigger_reason: "zero_survivors" | "new_hypothesis_indicated"

	diagnosis:
		"exhaustiveness_failed" |  // bounded+exhaustive only
		"space_needs_expansion" |  // bounded+non-exhaustive
		"new_hypotheses_needed"    // unbounded

	resolution:
		"revise_observation"    |  // exhaustiveness_failed
		"expand_space"          |  // space_needs_expansion
		"generate_hypotheses"   |  // new_hypotheses_needed
		"close_as_exhausted"       // budget exceeded or expansion unproductive

	new_hypotheses: [...#Hypothesis] // populated when resolution is expand_space or generate_hypotheses

	// Constraints on new hypotheses: they must not be inconsistent with
	// evidence that survived Phase 2 with "consistent" assessments.
	consistency_constraints: [...string]

	revision_count: uint // increments each time Phase 3b is triggered
	notes:          string
}

#ConfidenceAssessment: {
	hypothesis_id: string
	level:         "high" | "medium" | "low"
	argument:      string // explicit reasoning against the factors above
	// What would weaken this confidence assessment?
	vulnerabilities: [...string]
}

#DiscriminatingExperiment: {
	design:          string // how to discriminate between surviving hypotheses
	targets:         [...string] // hypothesis ids it would discriminate between
	feasible:        bool
	if feasible {
		expected_discriminating_power: "decisive" | "strong" | "weak"
	}
	if !feasible {
		feasibility_blocker: string
		// Even if not feasible now, document what would make it feasible.
		theoretical_path: string
	}
}

#Phase4: {
	single_survivor: bool

	if single_survivor {
		confidence: #ConfidenceAssessment
	}

	if !single_survivor {
		// Attempt to design discriminating experiments.
		discriminating_experiments: [...#DiscriminatingExperiment]
		// If any feasible discriminating experiment exists, it should be
		// executed and Phase 3 re-run with the new evidence.
		feasible_discrimination_available: bool
	}
}

#ExplanationObligation: {
	property:  string
	argument:  string
	satisfied: bool
	if !satisfied {
		blocker: string
	}
}

#Phase5: {
	obligations:   [...#ExplanationObligation]
	all_satisfied: bool
}

#AdoptedExplanation: {
	hypothesis_id:            string
	cause:                    string // restated from the surviving hypothesis
	confidence:               "high" | "medium" | "low"
	acknowledged_limitations: [...string]
	remaining_vulnerabilities: [...string]
	// What evidence would overturn this explanation?
	// Declared explicitly so future observers know what to look for.
	overturning_evidence:     string
}

// In the "open" outcome, document the surviving hypotheses and what
// would discriminate between them.
#OpenRecord: {
	survivors: [...string] // hypothesis ids
	// What evidence would discriminate between them if obtainable?
	theoretical_discriminator: string
	// Why is discrimination not currently achievable?
	underdetermination_reason: string
}

#Phase6: {
	if outcome == "converged" {
		adopted: #AdoptedExplanation
	}
	if outcome == "open" {
		open_record: #OpenRecord
	}
	if outcome == "exhausted" {
		// Document what the exhaustion implies for next steps.
		exhaustion_notes: string
		recommended_next: string
	}
	outcome: #Outcome
}

#Outcome: "converged" | "open" | "exhausted"

#HEPInstance: {
	protocol:  #Protocol
	phenomenon: #Phenomenon
	mode:      #ModeDeclaration
	version:   string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3

	derived: #Derived

	phase3b?: #Phase3b

	phase4: #Phase4
	phase5: #Phase5
	phase6: #Phase6

	outcome:       #Outcome
	outcome_notes: string
	// For bounded+exhaustive runs: note whether the exhaustiveness argument
	// survived the run intact or was weakened by scope narrowings.
	exhaustiveness_status?: string
}
