package ptp

#Protocol: {
	name:        "Prioritization Triage Protocol"
	version:     "0.1.0"
	description: "Resource-constrained path selection. All options are valid; PTP ranks them strategically."
}

#Option: {
	id:           string
	description:  string
	kind:         "canonical_form" | "protocol_run" | "implementation_path" | "other"
	expected_value: string // what value or output selecting this option produces
	dependencies:  [...string] // what must exist before this option can be executed
	reversible:    bool
	if !reversible {
		irreversibility_notes: string
	}
}

#ResourceConstraint: {
	kind:        "time" | "effort" | "budget" | "attention" | "dependency_order"
	description: string
	limit:       string // actual constraint value (e.g. "2 weeks", "one sprint")
}

#Phase1: {
	options:     [...#Option]
	options:     [_, _, ...] // at least two required — ranking one option is trivial
	constraints: [...#ResourceConstraint]
}

#Criterion: {
	id:               string
	name:             string
	description:      string
	weight?:          uint   // explicit numeric weight; higher = more important
	weight_rationale: string // why this weight was assigned
}

#Phase2: {
	criteria:           [...#Criterion]
	criteria:           [_, ...]
	weighting_approach: "numeric" | "ordinal"
	criteria_rationale: string // why these criteria were selected
}

#CriterionScore: {
	criterion_id: string
	option_id:    string
	score:        "high" | "medium" | "low" | "unknown"
	argument:     string // why this option scores this way on this criterion
}

#Phase3: {
	scores:             [...#CriterionScore]
	coverage_argument:  string // confirmation that all option × criterion pairs were assessed
}

#RankedOption: {
	rank:        uint
	option_id:   string
	rationale:   string // why this option is ranked here
	sensitivity: "stable" | "unstable"
	if sensitivity == "unstable" {
		sensitivity_notes: string // which weight change would change the rank
	}
}

#Phase4: {
	ranked_options:           [...#RankedOption]
	ranked_options:           [_, ...]
	sensitivity_summary:      string // how robust is the top ranking overall?
	top_rank_vulnerabilities: [...string] // what would change the top-ranked option?
}

#DeprioritizedRecord: {
	option_id:                string
	reason:                   string
	re_evaluation_conditions: string // when to revisit this decision
}

#Phase5: {
	decision:              string // plain-language summary of the ranking
	top_choice:            string // option_id
	top_rationale:         string
	deprioritized:         [...#DeprioritizedRecord]
	re_evaluation_trigger: string // event or condition that should prompt re-ranking
	override_conditions:   string // conditions under which the ranking should NOT be followed
}

#Outcome: "ranked" | "tied" | "insufficient_data"

#PTPInstance: {
	protocol: #Protocol
	version:  string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3
	phase4: #Phase4
	phase5: #Phase5

	outcome:       #Outcome
	outcome_notes: string
}
