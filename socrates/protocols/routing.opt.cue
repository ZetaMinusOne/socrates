package routing

#StructuralFeature:
	"term_inconsistency"          | // term used differently across contexts → CBP
	"competing_candidates"        | // multiple formalisms competing → CFFP
	"unknown_design_space"        | // design space not yet understood → ADP
	"argument_fragility"          | // existing argument needs stress-testing → AAP
	"construct_incoherence"       | // construct seems to be two things → CDP
	"causal_ambiguity"            | // multiple explanations for phenomenon → HEP
	"cross_run_conflict"          | // independent runs need reconciling → RCP
	"implementation_gap"          | // implementation vs canonical dispute → IFA
	"revision_pressure"           | // canonical form proposed for change → CGP
	"deprecation_pressure"        | // canonical form proposed for retirement → CGP
	"structural_transfer"         | // cross-domain analogy being claimed → ATP
	"composition_emergence"       | // unexpected behavior at component seams → EMP
	"observation_validity"        | // empirical claim needs validation → OVP
	"resource_constrained_choice"   // multiple valid paths, finite resources → PTP

#KnownProtocol:
	"AAP" | "ADP" | "ATP" | "CBP" | "CDP" | "CFFP" | "CGP" |
	"EMP" | "HEP" | "IFA" | "OVP" | "PTP" | "RCP"

// Each entry maps one structural feature to its primary protocol.
#FeatureProtocolMapping: {
	feature:          #StructuralFeature
	primary_protocol: #KnownProtocol
	confidence:       "high" | "medium" | "low"
	conditions:       string // when this mapping is valid
	exceptions:       string // when a different protocol is more appropriate
	prerequisites:    [...#KnownProtocol]
}

#DisambiguationRule: {
	when:            [...#StructuralFeature] // these features co-occur
	prefer:          #KnownProtocol          // prefer this protocol first
	because:         string
	run_other_after: bool
	other_protocol?: #KnownProtocol
}

#RoutingInput: {
	problem_statement:   string
	structural_features: [...#StructuralFeature]
	structural_features: [_, ...] // at least one required
	context:             string   // additional context for disambiguation
}

#SequencedStep: {
	order:    uint
	protocol: #KnownProtocol
	purpose:  string // why this step is in the sequence
	feeds:    string // what this step's output feeds into
}

#RoutingResult: {
	primary:   #KnownProtocol
	secondary: [...#KnownProtocol]
	sequenced: bool
	if sequenced {
		sequence: [...#SequencedStep]
		sequence: [_, ...]
	}
	rationale:     string
	warnings:      [...string]
	outcome:       "routed" | "ambiguous" | "unroutable"
	outcome_notes: string
}
