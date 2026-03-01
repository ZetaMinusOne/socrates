package cbp

#Protocol: {
	name:        "Concept Boundary Protocol"
	version:     "0.1.1"
	description: "Usage-driven concept boundary determination. Output is a sharpened definition or a named split."
}

#TermUnderInvestigation: {
	term:        string // the exact term or phrase being investigated
	domain:      string // the field, codebase, discourse, or context where this matters
	// Why is this investigation being conducted now?
	// What problem does the inconsistent usage cause?
	motivation:  string
	// Are there already competing formal definitions in the literature or codebase?
	prior_definitions: [...{
		source:     string
		definition: string
		notes:      string
	}]
}

#UsageIntent:
	"technical"     | // used as a precise technical term
	"colloquial"    | // used loosely or informally
	"metaphorical"  | // used by analogy or extension
	"contested"     | // speaker is aware of definitional dispute
	"ambiguous"       // intent cannot be determined from context

#Usage: {
	id:      string
	source:  string // where this usage was found (document, speaker, codebase, etc.)
	excerpt: string // the actual usage in context
	// What did the user apparently mean by this term here?
	apparent_meaning: string
	intent:           #UsageIntent
	// Is this usage consistent with other usages, or does it diverge?
	diverges_from: [...string] // usage ids this one is inconsistent with
	// Is this a core usage (clearly central to the term's identity)
	// or a peripheral usage (possibly metaphorical or derived)?
	centrality: "core" | "peripheral"
}

#Phase1: {
	procedure_log: [...{
		procedure: "contextual_sampling" | "edge_case_elicitation" | "expert_probe"
		applied:   bool
		if !applied {
			skip_justification: string
		}
		notes: string
	}]

	usages: [...#Usage]
	usages: [_, ...] // at least one required

	// Evaluator's synthesis: what is the pattern of divergence?
	// Are there clearly distinct semantic clusters, or is the divergence diffuse?
	divergence_summary: string

	// Preliminary diagnosis before candidates are proposed.
	preliminary_diagnosis: "likely_sharpening" | "likely_split" | "likely_retirement" | "unclear"
}

#UsageCoverage: {
	usage_id:  string
	covered:   bool
	if covered {
		explanation: string // how this candidate covers this usage
	}
	if !covered {
		diagnosis: string // why this usage is excluded (error, metaphor, out of scope)
		diagnosis_kind: "error" | "metaphor" | "domain_extension" | "out_of_scope"
	}
}

#ConceptName: {
	proposed_name:   string
	naming_rationale: string // argument that this name satisfies naming criteria
	// What prior terms or concepts might this name be confused with?
	confusion_risks: [...string]
	// How are those confusion risks mitigated?
	confusion_mitigations: [...string]
}

#SharpeningCandidate: {
	id:         string
	kind:       "sharpening"
	definition: string // the proposed precise definition
	// Necessary and sufficient conditions, if expressible.
	necessary_conditions:  [...string]
	sufficient_conditions: [...string]
	// How does this definition handle the divergent usages?
	divergence_diagnosis: string
	coverage: [...#UsageCoverage]
	// What this definition explicitly excludes and why.
	explicit_exclusions: [...string]
}

#SplitConceptDefinition: {
	name:               #ConceptName
	definition:         string
	boundary_criterion: string // what makes something an instance of this concept and not others
	// Necessary and sufficient conditions, if expressible.
	necessary_conditions:  [...string]
	sufficient_conditions: [...string]
	// Which usages from Phase 1 map to this concept?
	mapped_usages: [...string] // usage ids
}

#SplitCandidate: {
	id:       string
	kind:     "split"
	concepts: [...#SplitConceptDefinition]
	concepts: [_, _, ...] // at least two concepts required

	// What happens to the original term?
	original_term_disposition:
		"retired"        | // original term no longer used
		"assigned"       | // original term assigned to one of the split concepts
		"umbrella"         // original term retained as umbrella for all concepts
	if original_term_disposition == "assigned" {
		assigned_to: string // concept name it is assigned to
		assignment_rationale: string
	}
	if original_term_disposition == "umbrella" {
		umbrella_rationale: string // why the original term works as an umbrella
	}

	coverage: [...#UsageCoverage]
}

#ReplacementTerm: {
	term:       string
	definition: string
	// Which usages from Phase 1 does this replacement term cover?
	mapped_usages: [...string]
}

#RetirementCandidate: {
	id:                   string
	kind:                 "retirement"
	retirement_rationale: string // why the term cannot be sharpened or split
	replacements:         [...#ReplacementTerm]
	replacements:         [_, ...] // at least one replacement required
	coverage:             [...#UsageCoverage]
}

#ResolutionCandidate: #SharpeningCandidate | #SplitCandidate | #RetirementCandidate

#Phase2: {
	candidates: [...#ResolutionCandidate]
	candidates: [_, ...] // at least one required
}

#DefinitionRebuttal: {
	kind:     "refutation" | "scope_narrowing"
	argument: string
	valid:    bool
	limitation_description?: string // required if scope_narrowing
}

#CoverageGapChallenge: {
	id:               string
	target_candidate: string
	usage_id:         string // the uncovered usage
	argument:         string // why this usage is not covered or diagnosed
	rebuttal?:        #DefinitionRebuttal
}

#DefinitionCollisionChallenge: {
	id:               string
	target_candidate: string
	usage_id_a:       string
	usage_id_b:       string
	argument:         string // why these usages resist assignment to the same concept
	rebuttal?:        #DefinitionRebuttal
}

#NamingCriterion: "distinctness" | "non_prejudging" | "coverage" | "memorability"

#NamingPressureChallenge: {
	id:               string
	target_candidate: string
	target_concept:   string // the concept name being challenged
	criterion:        #NamingCriterion
	argument:         string // why the name fails this criterion
	rebuttal?: {
		argument: string
		valid:    bool
		// If invalid: the candidate must revise the name.
		// Name revision does not eliminate the candidate.
		revised_name?: #ConceptName // populated if rebuttal is invalid
	}
}

#ConnotationPressureChallenge: {
	id:               string
	target_candidate: string
	// Which term or concept does this definition/name import connotations from?
	connotation_source: string
	argument:           string // how the connotation is imported and why it is harmful
	rebuttal?: {
		argument: string
		valid:    bool
	}
}

#Phase3: {
	coverage_gaps:        [...#CoverageGapChallenge]
	definition_collisions: [...#DefinitionCollisionChallenge]
	naming_pressure:      [...#NamingPressureChallenge]
	connotation_pressure: [...#ConnotationPressureChallenge]
}

#EliminationReason:
	"coverage_gap_unrebutted"        |
	"definition_collision_unrebutted" |
	"connotation_pressure_unrebutted" |
	"naming_revision_failed"

#EliminatedCandidate: {
	candidate_id: string
	reason:       #EliminationReason
	source_id:    string
}

#SurvivorCandidate: {
	candidate_id:     string
	kind:             "sharpening" | "split" | "retirement"
	scope_narrowings: [...string]
	// Name revisions applied during pressure phase.
	name_revisions: [...{
		concept:      string
		original:     string
		revised:      string
		revision_rationale: string
	}]
}

#Derived: {
	eliminated: [...#EliminatedCandidate]
	survivors:  [...#SurvivorCandidate]
}

#Phase3b: {
	triggered:  bool
	diagnosis:  "usages_insufficient" | "candidates_too_weak" | "term_irredeemable"
	resolution: "collect_more_usages" | "revise_candidates" | "close_as_retired"
	notes:      string
}

#CandidateSelection: {
	selected:        string // candidate id
	selection_basis: string // explicit reasoning against the criteria above
	alternatives_rejected: [...{
		candidate_id: string
		reason:       string
	}]
}

#Phase4: {
	multiple_survivors: bool
	if multiple_survivors {
		selection: #CandidateSelection
	}
	final_candidate: string
}

#ResolutionObligation: {
	property:  string
	argument:  string
	satisfied: bool
	if !satisfied {
		blocker: string
	}
}

#Phase5: {
	obligations:   [...#ResolutionObligation]
	all_satisfied: bool
}

#SharpenedDefinition: {
	term:                  string
	definition:            string
	necessary_conditions:  [...string]
	sufficient_conditions: [...string]
	usage_coverage:        [...#UsageCoverage]
	acknowledged_limitations: [...string]
	// Usages diagnosed as errors, metaphors, or extensions.
	variant_diagnoses: [...{
		usage_id:  string
		diagnosis: "error" | "metaphor" | "domain_extension" | "out_of_scope"
		notes:     string
	}]
}

#VocabularyMap: {
	concepts: [...{
		name:               string
		definition:         string
		boundary_criterion: string
		mapped_usages:      [...string]
		acknowledged_limitations: [...string]
		// Does this concept warrant a CFFP or CDP run?
		downstream_protocol?: "cffp" | "cdp" | "none"
		downstream_notes?:    string
	}]
	original_term_disposition:
		"retired" | "assigned" | "umbrella"
	original_term_notes: string
}

#ReplacementVocabulary: {
	retired_term:  string
	retirement_rationale: string
	replacements:  [...#ReplacementTerm]
	usage_coverage: [...#UsageCoverage]
}

#AdoptedResolution: {
	kind: "sharpening" | "split" | "retirement"

	if kind == "sharpening" {
		sharpened: #SharpenedDefinition
	}
	if kind == "split" {
		vocabulary_map: #VocabularyMap
	}
	if kind == "retirement" {
		replacement_vocabulary: #ReplacementVocabulary
	}

	// Open questions: usages or distinctions that remain contested
	// even after the resolution is adopted.
	open_questions: [...string]

	// Plain-language summary for human observers.
	summary: string
}

#Phase6: {
	adopted_resolution: #AdoptedResolution
}

#Outcome: "sharpened" | "split" | "retired" | "open"

#CBPInstance: {
	protocol: #Protocol
	term:     #TermUnderInvestigation
	version:  string

	phase1: #Phase1
	phase2: #Phase2
	phase3: #Phase3

	derived: #Derived

	phase3b?: #Phase3b

	phase4?: #Phase4 // only if len(derived.survivors) > 1

	phase5: #Phase5
	phase6?: #Phase6 // only if phase5.all_satisfied == true

	outcome:       #Outcome
	outcome_notes: string
}
