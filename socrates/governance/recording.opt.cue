package recording

#SourceProtocol:
	"AAP" | "ADP" | "ATP" | "CBP" | "CDP" | "CFFP" | "CGP" |
	"EMP" | "HEP" | "IFA" | "OVP" | "PTP" | "RCP"

#SourceRun: {
	protocol:    #SourceProtocol
	run_id:      string
	run_version: string
	subject:     string
	started:     string // ISO 8601
	completed:   string // ISO 8601
}

#DisputeKind:
	"term_ambiguity"        |
	"candidate_selection"   |
	"assumption_audit"      |
	"design_mapping"        |
	"construct_repair"      |
	"implementation_check"  |
	"governance_case"       | // was revision_proposal + deprecation_case; now CGP
	"cross_run_conflict"    |
	"analogy_transfer"      | // ATP
	"composition_emergence" | // EMP
	"observation_validity"  | // OVP
	"prioritization"          // PTP

#DisputeCharacterization: {
	kind:        #DisputeKind
	description: string
	prior_runs:  [...string] // run_ids of prior relevant runs
}

#ResolutionStatus: "decided" | "open" | "rejected"

#ResolutionSummary: {
	status:           #ResolutionStatus
	decision?:        string
	open_questions?:  [...string]
	eliminated_count: int | *0
	survivors:        [...string]
}

#AcknowledgedLimitation: {
	description: string
	source:      string // which phase or challenge produced this limitation
}

#Dependencies: {
	consumed: [...string] // run_ids this run depended on
	produced: [...string] // artifacts this run produced
}

#NextAction: {
	action:    string
	protocol?: #SourceProtocol
	rationale: string
}

#Record: {
	record_id: string

	source_run:               #SourceRun
	dispute:                  #DisputeCharacterization
	resolution:               #ResolutionSummary
	acknowledged_limitations: [...#AcknowledgedLimitation]
	dependencies:             #Dependencies
	tags:                     [...string]
	next_actions:             [...#NextAction]
	notes:                    string | *""
}
