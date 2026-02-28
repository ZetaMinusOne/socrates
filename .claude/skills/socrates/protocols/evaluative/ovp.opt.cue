package ovp

#Protocol: {
	name:        "Observation Validation Protocol"
	version:     "0.1.0"
	description: "Empirical observation validation. Gates HEP — validates phenomena are real before hypothesis elimination."
}

#Phase1: {
	phenomenon:         string  // the claimed observation, stated precisely
	measurement_method: string  // how the observation was made or collected
	context:            string  // conditions, environment, timing
	reproducible:       bool
	if !reproducible {
		reproducibility_notes: string // what this implies for validity
	}
	claim_source:      string   // who or what made the original claim
	prior_validations: [...string] // prior attempts to validate, if any
}

#ValidityCriterion:
	"measurement_validity" |
	"selection_bias"       |
	"confounding_factors"  |
	"sample_adequacy"      |
	"reporting_accuracy"   |
	"reproducibility"

#ValidityEvaluation: {
	criterion: #ValidityCriterion
	verdict:   "passes" | "fails" | "indeterminate"
	argument:  string
	if verdict == "fails" {
		severity:            "fatal" | "significant" | "minor"
		artifact_hypothesis: string // what might explain the observation as an artifact
	}
}

#Phase2: {
	evaluations: [...#ValidityEvaluation]
	// All six criteria must be evaluated or explicitly skipped.
	skipped_criteria: [...{
		criterion:     #ValidityCriterion
		justification: string
	}]
	summary: string // evaluator's synthesis of the validity landscape
}

#ValidityChallenge: {
	id:                   string
	kind:                 #ValidityCriterion
	argument:             string // specific challenge to the observation's validity
	severity:             "fatal" | "significant" | "minor"
	resolution_condition: string // what would resolve this challenge
}

#Phase3: {
	challenges:           [...#ValidityChallenge]
	// Evaluator's synthesis: do the challenges, taken together, undermine the observation?
	aggregate_assessment: string
}

#OVPVerdict: "validated" | "contested" | "artifact"

#ValidatedObservation: {
	phenomenon:   string
	confidence:   "high" | "medium"
	caveats:      [...string] // residual concerns to carry into HEP
}

#Phase4: {
	verdict:   #OVPVerdict
	rationale: string

	if verdict == "validated" {
		validated_observation: #ValidatedObservation
	}

	if verdict == "contested" {
		validation_path:     string // what would upgrade this to validated
		usable_with_caveats: bool
		if usable_with_caveats {
			required_caveats: [...string]
		}
	}

	if verdict == "artifact" {
		artifact_explanation: string  // what the observation actually shows
		underlying_signal?:   string  // genuine phenomenon, if any, the artifact points toward
	}
}

#Outcome: "validated" | "contested" | "artifact"

#OVPInstance: {
	protocol: #Protocol
	version:  string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3
	phase4: #Phase4

	outcome:       #Outcome
	outcome_notes: string
}
