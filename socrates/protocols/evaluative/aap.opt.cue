package aap

#Protocol: {
	name:        "Assumption Audit Protocol"
	version:     "0.1.1"
	description: "Forensic assumption extraction and stress-testing. Output is a ranked fragility map."
}

#AuditSubject: {
	name:        string
	kind:        "argument" | "design" | "policy" | "model" | "specification"
	description: string
	// The conclusion or output the subject claims to produce.
	// This is the thing that may be degraded or invalidated when assumptions fail.
	claimed_conclusion: string
	// Arguments or designs this subject explicitly builds on.
	// Their assumptions are candidates for inheritance in Phase 1.
	depends_on: [...string]
	// The original source or statement of the argument or design, if available.
	source?: string
}

#AssumptionClass:
	"inferential"   | // required for an inference step to be valid
	"parametric"    | // treats a variable as fixed
	"scope"         | // defines what the argument covers and excludes
	"environmental" | // assumes conditions in the surrounding context
	"behavioral"    | // assumes how agents or systems will act
	"inherited"       // assumed from a dependency

#ExtractionProcedure: "inference_step" | "fixed_variable" | "ignored_factor" | "inherited"

#Assumption: {
	id:          string
	description: string // precise statement of what is being assumed
	class:       #AssumptionClass
	extracted_by: #ExtractionProcedure

	locus: string

	preliminary_load: "structural" | "significant" | "moderate" | "minor"

	// Is this assumption explicitly stated in the original argument,
	// or was it extracted (implicit)?
	explicit: bool

	// Is this assumption empirically checkable, or is it non-empirical
	// (definitional, normative, structural)?
	empirically_checkable: bool
	if empirically_checkable {
		check_procedure?: string // how one would verify this assumption holds
	}
}

#Phase1: {
	// Record of which extraction procedures were applied and any skips.
	procedure_log: [...{
		procedure: #ExtractionProcedure
		applied:   bool
		if !applied {
			skip_justification: string
		}
		notes: string // what the procedure surfaced or why it was unproductive
	}]

	assumptions: [...#Assumption]
	assumptions: [_, ...] // at least one required

	// Evaluator's synthesis: which assumptions appear most load-bearing
	// before stress-testing, and why.
	preliminary_assessment: string
}

#PlausibilityAssessment: {
	assumption_id: string
	plausibility:  "high" | "medium" | "low" | "unknown"
	argument:      string // why this plausibility is assigned
	// Under what conditions would plausibility drop?
	conditional_fragility: string
}

#VerifiabilityAssessment: {
	assumption_id: string
	verifiable:    bool
	if verifiable {
		verified:    bool
		if verified {
			evidence: string // what establishes this assumption holds
		}
		if !verified {
			verification_path: string // how it could be verified
		}
	}
	if !verifiable {
		reason: string // why this assumption cannot be verified
	}
}

#CouplingRecord: {
	assumption_id: string
	coupled_with:  [...string] // assumption ids
	// Why are these coupled? What shared dependency or mutual reinforcement
	// makes them fail together?
	coupling_reason: string
}

#AssumptionCluster: {
	id:           string
	member_ids:   [...string] // assumption ids in this cluster
	// What does this cluster collectively assume?
	joint_assumption: string
	// How fragile is the cluster as a whole?
	cluster_fragility: "structural" | "significant" | "moderate" | "minor"
}

#Phase2: {
	plausibility:    [...#PlausibilityAssessment]
	verifiability:   [...#VerifiabilityAssessment]
	coupling:        [...#CouplingRecord]
	clusters:        [...#AssumptionCluster]
	// Evaluator's synthesis of the coupling landscape.
	coupling_summary: string
}

#FailureScenario: {
	id:          string
	description: string // the concrete situation in which the assumption fails
	realistic:   bool & true
	minimal:     bool & true
	targeted:    bool & true
}

#StressTestResult: {
	assumption_id:    string
	// For cluster stress tests, cluster_id is set instead.
	cluster_id?:      string
	scenario:         #FailureScenario
	impact:           "invalidates" | "degrades" | "scopes" | "negligible"
	impact_argument:  string // how the failure propagates to the conclusion
	// Refined load estimate, replacing preliminary_load from Phase 1.
	refined_load:     "structural" | "significant" | "moderate" | "minor"
	// If impact is "degrades" or "scopes": what does the weakened conclusion look like?
	weakened_conclusion?: string
	patchable:        "yes" | "partial" | "no"
	patch_description?: string // required if patchable is "yes" or "partial"
}

#UnstressableAssumption: {
	assumption_id: string
	reason:        "necessarily_true" | "argument_underspecified" | "impact_untraceable"
	notes:         string
}

#Phase3: {
	stress_tests:          [...#StressTestResult]
	unstressable:          [...#UnstressableAssumption]
	// All assumptions must either have a stress test or an unstressable record.
	// Enforced by protocol evaluator.
}

#FragilityTier: {
	tier:        1 | 2 | 3 | 4
	label:       "structural" | "significant" | "moderate" | "minor"
	members:     [...string] // assumption ids and/or cluster ids at this tier
	// Summary of what this tier's failure means for the conclusion.
	tier_summary: string
}

#FragilityMap: {
	tiers: [...#FragilityTier]

	// The single assumption or cluster whose failure poses the greatest risk.
	// Greatest risk = highest load AND lowest plausibility.
	most_dangerous:    string // assumption or cluster id
	most_dangerous_argument: string // why this is the most dangerous

	// The single improvement that would most strengthen the argument.
	// Most verifiable improvement = highest load, verifiable, currently unverified.
	most_verifiable_improvement:    string // assumption id
	most_verifiable_improvement_argument: string

	// Assumptions that are both structural (Tier 1) and unverifiable.
	// These represent irreducible epistemic risk.
	irreducible_risks: [...string] // assumption ids
	irreducible_risk_summary: string // what this means for the argument's reliability

	// Overall fragility assessment.
	overall_fragility: "brittle" | "fragile" | "robust" | "resilient"
	overall_argument: string
}

#Phase4: {
	fragility_map: #FragilityMap
}

#Recommendation: {
	id:            string
	assumption_id: string // or cluster_id
	kind:          "verify" | "hedge" | "patch" | "investigate" | "accept"
	description:   string // what specifically to do
	expected_impact: string // how this would change the fragility map
	priority:      "high" | "medium" | "low"
}

#Phase5: {
	recommendations: [...#Recommendation]
	// Evaluator's summary: if only one recommendation could be acted on,
	// which one and why?
	top_recommendation: string
}

#AuditRecord: {
	subject:           string // name of the argument or design audited
	outcome:           #Outcome
	fragility_map:     #FragilityMap
	total_assumptions: uint
	explicit_assumptions: uint   // how many were stated by the author
	extracted_assumptions: uint  // how many were surfaced by the protocol
	tier_counts: {
		tier1: uint
		tier2: uint
		tier3: uint
		tier4: uint
	}
	recommendations:   [...#Recommendation]
	// Plain-language summary for human observers.
	summary: string
	// What would a materially stronger version of this argument look like?
	strengthened_form: string
}

#Phase6: {
	audit_record: #AuditRecord
}

#Outcome: "mapped" | "incomplete" | "incoherent"

#AAPInstance: {
	protocol: #Protocol
	subject:  #AuditSubject
	version:  string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3
	phase4: #Phase4
	phase5: #Phase5
	phase6: #Phase6

	outcome:       #Outcome
	outcome_notes: string
}
