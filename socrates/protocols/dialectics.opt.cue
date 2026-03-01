package dialectics

#Rebuttal: {
	kind:     "refutation" | "scope_narrowing"
	argument: string
	valid:    bool
	// Required when kind is "scope_narrowing": what scope was excluded.
	// This text becomes an entry in the survivor's scope_narrowings list.
	limitation_description?: string
}

#Challenge: {
	id:               string
	target_candidate: string
	argument:         string
	minimal:          bool | *false // must be true for counterexample-type challenges
	rebuttal?:        #Rebuttal
}

#EliminationRecord: {
	candidate_id: string
	reason:       string // protocol-specific elimination reason
	source_id:    string // id of the challenge that caused elimination
}

#SurvivorRecord: {
	candidate_id:     string
	scope_narrowings: [...string] // from scope_narrowing rebuttals; become acknowledged limitations
}

#Derivation: {
	eliminated: [...#EliminationRecord]
	survivors:  [...#SurvivorRecord]
}

#Obligation: {
	property:  string
	argument:  string
	satisfied: bool
	if !satisfied {
		blocker: string
	}
}

#ObligationGate: {
	obligations:   [...#Obligation]
	all_satisfied: bool
}

#RevisionLoop: {
	triggered:  bool
	diagnosis:  string // protocol-specific diagnosis enum
	resolution: string // protocol-specific resolution enum
	notes:      string
}

#FindingKind:
	"contradiction" | // two claims cannot both be true
	"gap"           | // something expected is missing
	"ambiguity"     | // a claim could mean multiple things
	"decision"      | // a choice was made with explicit rationale
	"dependency"    | // a relation between protocol outputs
	"risk"          | // a potential failure mode
	"limitation"      // a known scope boundary

#Finding: {
	kind:      #FindingKind
	content:   string
	severity?: "fatal" | "significant" | "minor"
	source?:   string
}

#Adversarial: {
	has_candidates:      bool & true
	has_pressure:        bool & true
	has_derivation:      bool & true
	has_revision_loop:   bool & true
	has_selection:       bool & true
	has_obligation_gate: bool & true
	has_adoption:        bool & true
}

// Evaluative protocols: AAP, IFA, RCP, CGP, OVP, PTP
#Evaluative: {
	has_subject:    bool & true
	has_criteria:   bool & true
	has_assessment: bool & true
	has_verdict:    bool & true
}

// Exploratory protocols: ADP
#Exploratory: {
	has_subject:  bool & true
	has_rounds:   bool & true
	has_referee:  bool & true
	has_map:      bool & true
}

#KnownProtocol:
	"AAP" | "ADP" | "ATP" | "CBP" | "CDP" | "CFFP" | "CGP" |
	"EMP" | "HEP" | "IFA" | "OVP" | "PTP" | "RCP"

#SuiteConstraints: {
	routing_complete:      bool & true
	recording_complete:    bool & true
	reachability_complete: bool & true
}

#Run: {
	protocol_name:  #KnownProtocol
	run_id:         string
	version:        string
	started:        string  // ISO 8601
	completed?:     string  // ISO 8601 — absent if run is not yet complete
	outcome:        string  // protocol-specific outcome value
	outcome_notes:  string
	// Assertion that this run can be projected into a #Record.
	recordable:     bool & true
}
