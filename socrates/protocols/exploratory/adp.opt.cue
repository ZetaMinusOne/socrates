package adp

#ADPPersona: "formalist" | "implementor" | "adversary" | "operator" | "consumer" | "referee"

#PersonaMandate: {
	[#ADPPersona]: string
} & {
	"formalist":   "Decidability, completeness, soundness. Every construct must have formal guarantees or be rejected. Invokes design constraints as rejection criteria. Finds places where informal semantics will cause implementer divergence."
	"implementor": "Feasibility, performance, operational reality. Knows what gets built under deadline pressure. Finds the gap between what the spec says and what actually ships."
	"adversary":   "Hostile or naive implementer. Finds every place where spec intent and spec text diverge. Asks: what is the most wrong-but-technically-conforming implementation I could build? Makes specs tight."
	"operator":    "Production deployment, versioning, migration, observability, incident response. Asks what happens when this goes wrong at 2am. Finds operability gaps the other personas miss."
	"consumer":    "End user of whatever is being designed, human or machine. Asks whether the output is actually usable. Finds ergonomic failures and documentation gaps only visible from the outside."
	"referee":     "Neutral process management. Does not advocate. Applies design constraint checks. Identifies convergence and live issues. Declares CFFP-ready or exhaustion."
}

#ADPSubject: {
	// A new language construct or protocol being designed from scratch.
	// Personas explore the problem space and surface constraints.
	new_construct?: {
		name:        string
		description: string
		// Known constraints that must be satisfied. These are not negotiable.
		// Personas argue about how to satisfy them, not whether to.
		constraints: [...string]
	}

	// A new domain being modeled for the first time.
	// Personas explore what facts, entities, rules, and operations are needed.
	new_domain?: {
		name:        string
		description: string
	}

	// A proposed breaking change to an existing spec or system.
	// Personas explore impact before CFFP formalizes a migration path.
	breaking_change?: {
		what:   string // what is changing
		why:    string // why it needs to change
		impact: string // known or suspected impact
	}

	// A governance or design decision with no obvious candidates.
	// Personas explore the option space before narrowing to candidates.
	decision?: {
		question:    string
		context:     string
		constraints: [...string]
	}
}

#ADPRoundType: "probe" | "pressure" | "synthesis" | "handoff"

// PersonaPosition is one persona's contribution to a round.
#PersonaPosition: {
	persona: #ADPPersona
	content: string // the persona's exploration, pressure, synthesis, or handoff position

	handoff_signal?: "ready" | "blocked"
	blocked_on?:     string // required when handoff_signal is "blocked"
}

// ADPRound is one full round of an ADP run.
#ADPRound: {
	round:     int // 1-indexed
	type:      #ADPRoundType
	positions: [...#PersonaPosition]

	referee_summary: string
}

#ConstraintCheck: {
	constraint:  string  // the constraint being checked
	failed:      bool
	offender?:   string  // the proposal or construct that failed, if any
	resolution?: string  // what must change to pass
}

#ConstraintCheckSet: {
	round:       int
	constraints: [...#ConstraintCheck]
	passed:      bool // true only if all checks have failed: false
}

#ExhaustionClass: "undecidable" | "scope" | "philosophical" | "complexity"

#UnresolvedObjection: {
	persona:        #ADPPersona
	classification: #ExhaustionClass
	description:    string // what the objection is
	next_stage_input: string // how this should be expressed as an invariant or acknowledged limitation
}

#DesignMap: {
	// The design space as understood after ADP.
	problem_statement: string

	invariants: [...string]

	candidate_directions: [...{
		name:        string
		description: string
		strengths:   [...string]
		weaknesses:  [...string]
	}]

	// Concerns that the next stage must address or formally scope out.
	open_questions: [...string]

	// Known constraints on the solution space.
	// Candidates that violate these are inadmissible.
	solution_constraints: [...string]
}

#ADPOutcome: "design_mapped" | "exhaustion" | "scope_reduction"

#ADPRecord: {
	// What was explored.
	subject: #ADPSubject

	// Design constraints applied this run.
	// For Tenor: C1-C7. For other systems: that system's constraints.
	design_constraints: [...string]

	// The full round-by-round record.
	rounds: [...#ADPRound]

	// Constraint check results per round.
	constraint_checks: [...#ConstraintCheckSet]

	// How the run ended.
	outcome: #ADPOutcome

	design_map?: #DesignMap

	// Present when outcome is "scope_reduction".
	// Documents why the scope was narrowed and what the new scope is.
	scope_reduction?: {
		original_subject: string
		rationale:        string
		narrowed_to:      string
	}

	unresolved_objections?: [...#UnresolvedObjection]

	// Total rounds run.
	rounds_count: int

	// The Referee's final declaration.
	referee_declaration: string
}
