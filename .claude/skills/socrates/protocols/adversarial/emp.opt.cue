package emp

#Protocol: {
	name:        "Emergence Mapping Protocol"
	version:     "0.1.0"
	description: "Composition emergence analysis. Maps unexpected behavior at canonical form boundaries."
}

#ComposedForm: {
	name:      string
	run_id:    string // the CFFP or equivalent run that produced it
	invariants: [...string]
}

#Phase1: {
	composed_forms:       [...#ComposedForm]
	composed_forms:       [_, _, ...] // at least two forms being composed
	emergent_behavior:    string      // the unexpected behavior observed
	interaction_boundary: string      // where the forms interact / the seam
	reproducible: bool
	if !reproducible {
		reproducibility_notes: string
	}
	observation_context: string // conditions under which the emergence was observed
}

#EmergenceKind:
	"interaction_effect"   | // behavior arises from the interaction rule between forms
	"missing_constraint"   | // one or both forms lacks a constraint that would prevent this
	"unmodeled_dependency" | // a shared dependency was not modeled in either form
	"genuine_novelty"        // the behavior cannot be reduced to any single form

#EmergenceCandidate: {
	id:            string
	kind:          #EmergenceKind
	description:   string
	causal_account: string // why this explanation produces the observed behavior

	// Is this behavior reducible to one of the composed forms?
	reducible_to?: string // name of the composed form, if reducible

	predictions: [...{
		id:             string
		description:    string // what else should be observable if this explanation is correct
		discriminating: bool
	}]
	predictions: [_, ...]
}

#Phase2: {
	candidates: [...#EmergenceCandidate]
	candidates: [_, ...]
}

#EmergenceRebuttal: {
	kind:     "refutation" | "scope_narrowing"
	argument: string
	valid:    bool
	limitation_description?: string // required if scope_narrowing
}

#ReductionChallenge: {
	id:               string
	target_candidate: string
	reduces_to:       string // which composed form explains the behavior
	argument:         string // how the form's invariants predict this behavior
	rebuttal?:        #EmergenceRebuttal
}

#ScopeChallenge: {
	id:               string
	target_candidate: string
	restricted_to:    string // conditions under which behavior occurs
	argument:         string // why the behavior doesn't generalize beyond this
	rebuttal?:        #EmergenceRebuttal
}

#CompositionCE: {
	id:               string
	target_candidate: string
	related_case:     string // a related composition where behavior does NOT occur
	minimal:          bool & true
	argument:         string // why this undermines the candidate's causal account
	rebuttal?:        #EmergenceRebuttal
}

#Phase3: {
	reduction_challenges:        [...#ReductionChallenge]
	scope_challenges:            [...#ScopeChallenge]
	composition_counterexamples: [...#CompositionCE]
}

#EliminationReason:
	"reduction_unrebutted"       |
	"scope_challenge_unrebutted" |
	"composition_ce_unrebutted"

#EliminatedExplanation: {
	candidate_id: string
	reason:       #EliminationReason
	source_id:    string
}

#SurvivorExplanation: {
	candidate_id:     string
	scope_narrowings: [...string] // conditions under which this explanation holds
}

#Derived: {
	eliminated: [...#EliminatedExplanation]
	survivors:  [...#SurvivorExplanation]
}

#Phase3b: {
	triggered:  bool
	diagnosis:  "candidates_too_weak" | "behavior_not_emergent" | "observation_insufficient"
	resolution: "revise_candidates" | "close_as_non_emergent" | "gather_more_observations"
	notes:      string
}

#Phase4: {
	multiple_survivors: bool
	if multiple_survivors {
		selected:        string
		selection_basis: string
		alternatives_rejected: [...{
			candidate_id: string
			reason:       string
		}]
	}
	final_candidate: string
}

#ImpactClassification:
	"benign"      | // emergence does not threaten any invariant of composed forms
	"degrading"   | // emergence weakens guarantees without breaking invariants
	"invalidating"  // emergence breaks an invariant of one or more composed forms

#ImpactObligation: {
	property:  string
	argument:  string
	satisfied: bool
	if !satisfied {
		blocker: string
	}
}

#Phase5: {
	obligations:     [...#ImpactObligation]
	all_satisfied:   bool
	impact:          #ImpactClassification
	impact_argument: string
}

#RemediationPath:
	"none_required"        | // benign — document and proceed
	"revise_one_form"      | // specify which form needs revision
	"revise_both_forms"    | // both composed forms need revision
	"add_composition_rule" | // an explicit constraint must be added to the composition
	"separate_forms"         // the forms should not be composed as specified

#EmergenceMap: {
	emergent_behavior:         string
	adopted_explanation:       string // the surviving explanation
	impact:                    #ImpactClassification
	acknowledged_scope_limits: [...string] // from scope narrowings
	remediation:               #RemediationPath
	if remediation == "revise_one_form" || remediation == "revise_both_forms" {
		forms_requiring_revision: [...string]
		revision_guidance:        string
	}
	if remediation == "add_composition_rule" {
		rule_description: string
	}
	// Follow-on protocol runs authorized by this emergence map.
	downstream_protocols: [...{
		protocol: string // "CGP", "CFFP", etc.
		purpose:  string
	}]
}

#NonEmergentRecord: {
	reduces_to:      string // which composed form fully explains the behavior
	explanation:     string
	recommendation:  string
}

#Phase6: {
	emergence_map?:      #EmergenceMap
	non_emergent_record?: #NonEmergentRecord
}

#Outcome: "mapped" | "non_emergent" | "open"

#EMPInstance: {
	protocol: #Protocol
	version:  string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3

	derived: #Derived

	phase3b?: #Phase3b

	phase4?: #Phase4

	phase5:  #Phase5
	phase6?: #Phase6

	outcome:       #Outcome
	outcome_notes: string
}
