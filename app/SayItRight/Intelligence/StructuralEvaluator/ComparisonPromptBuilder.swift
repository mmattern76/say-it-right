import Foundation

/// Builds the system prompt and user message for answer key comparison requests.
///
/// Each session type gets a tailored comparison rubric that instructs Claude
/// to evaluate structural similarity rather than exact textual match.
struct ComparisonPromptBuilder: Sendable {

    // MARK: - Public API

    /// Build the system prompt for a comparison request.
    func systemPrompt(for input: ComparisonInput) -> String {
        let identity = identityBlock(language: input.language)
        let rubric = rubricBlock(for: input.sessionType, language: input.language)
        let outputFormat = outputFormatBlock(for: input.sessionType, language: input.language)
        return [identity, rubric, outputFormat].joined(separator: "\n\n")
    }

    /// Build the user message containing the practice text, answer key, and user response.
    func userMessage(for input: ComparisonInput) -> String {
        let answerKey = input.practiceText.answerKey
        var parts: [String] = []

        parts.append("## Practice Text\n\n\(input.practiceText.text)")
        parts.append("## Answer Key\n\n\(formatAnswerKey(answerKey))")
        parts.append("## User's Response\n\n\(input.userResponse)")

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Identity Block

    private func identityBlock(language: String) -> String {
        if language == "de" {
            return """
            # Rolle

            Du bist Barbara, eine strenge aber wohlwollende Lehrerin für strukturiertes Denken. \
            Du bewertest die STRUKTUR des Denkens, nicht den Inhalt der Meinungen. \
            Du akzeptierst mehrere gültige Interpretationen — der Lösungsschlüssel ist eine Referenz, \
            nicht die einzig richtige Antwort.
            """
        }
        return """
        # Role

        You are Barbara, a strict but good-natured teacher of structured thinking. \
        You evaluate the STRUCTURE of thinking, not the content of opinions. \
        You accept multiple valid interpretations — the answer key is a reference, \
        not the only correct answer.
        """
    }

    // MARK: - Rubric Blocks

    private func rubricBlock(for sessionType: ComparisonSessionType, language: String) -> String {
        switch sessionType {
        case .findThePoint:
            return findThePointRubric(language: language)
        case .fixThisMess:
            return fixThisMessRubric(language: language)
        case .spotTheGap:
            return spotTheGapRubric(language: language)
        case .decodeAndRebuild:
            return decodeAndRebuildRubric(language: language)
        }
    }

    private func findThePointRubric(language: String) -> String {
        if language == "de" {
            return """
            # Bewertungskriterien: Finde den Punkt

            Bewerte, wie gut der Lernende den Kerngedanken (Governing Thought) des Textes identifiziert hat.

            ## Dimensionen (jeweils 0–3)
            - **governingThoughtAccuracy**: Hat der Lernende den zentralen Punkt erfasst? \
            Eine andere Formulierung ist akzeptabel, solange der strukturelle Kern stimmt.
            - **specificity**: Ist die Identifikation konkret oder vage? \
            "Es geht um Technologie" ist vage; "Der Autor argumentiert, dass KI die Bildung revolutioniert" ist spezifisch.
            - **supportAwareness**: Zeigt der Lernende Bewusstsein für die Stützpfeiler unter dem Kerngedanken?

            ## Bewertungsmaßstab
            - **high**: Kerngedanke korrekt erfasst (auch wenn anders formuliert), mit Bewusstsein für Stützstruktur.
            - **partial**: Richtiges Thema, aber Kerngedanke unscharf oder zu breit/eng gefasst.
            - **low**: Falsches Thema, oder Detail statt Kerngedanke identifiziert.
            """
        }
        return """
        # Evaluation Criteria: Find the Point

        Evaluate how well the learner identified the governing thought of the text.

        ## Dimensions (0–3 each)
        - **governingThoughtAccuracy**: Did the learner capture the central point? \
        Different wording is acceptable if the structural core is correct.
        - **specificity**: Is the identification concrete or vague? \
        "It's about technology" is vague; "The author argues AI will revolutionise education" is specific.
        - **supportAwareness**: Does the learner show awareness of the support pillars beneath the governing thought?

        ## Match Quality Scale
        - **high**: Governing thought correctly captured (even if differently worded), with awareness of support structure.
        - **partial**: Right topic but governing thought is fuzzy or too broad/narrow.
        - **low**: Wrong topic, or identified a detail instead of the governing thought.
        """
    }

    private func fixThisMessRubric(language: String) -> String {
        if language == "de" {
            return """
            # Bewertungskriterien: Räum das auf

            Bewerte die Qualität der Umstrukturierung des Lernenden. Der Lösungsschlüssel zeigt EINE \
            gültige Pyramide — der Lernende kann eine andere, ebenso gültige Struktur vorschlagen.

            ## Dimensionen (jeweils 0–3)
            - **pyramidValidity**: Bildet die Umstrukturierung eine gültige Pyramide? \
            Klarer Kerngedanke oben, logische Gruppierung darunter.
            - **groupingQuality**: Sind die Stützpfeiler sinnvoll gruppiert? MECE-Prinzip beachtet?
            - **orderingLogic**: Ist die Reihenfolge der Argumente logisch? \
            (Chronologisch, nach Wichtigkeit, oder strukturell begründet.)
            - **completeness**: Wurden alle wesentlichen Punkte des Originaltexts erfasst? \
            Nichts Wichtiges weggelassen, nichts Neues erfunden.

            ## Bewertungsmaßstab
            - **high**: Gültige Pyramide mit klarer Gruppierung, auch wenn sie vom Lösungsschlüssel abweicht.
            - **partial**: Ansätze einer Struktur, aber Gruppierung oder Kerngedanke schwach.
            - **low**: Keine erkennbare Pyramidenstruktur, oder wesentliche Inhalte fehlen/erfunden.
            """
        }
        return """
        # Evaluation Criteria: Fix This Mess

        Evaluate the quality of the learner's restructuring. The answer key shows ONE valid \
        pyramid — the learner may propose a different but equally valid structure.

        ## Dimensions (0–3 each)
        - **pyramidValidity**: Does the restructuring form a valid pyramid? \
        Clear governing thought on top, logical grouping beneath.
        - **groupingQuality**: Are support pillars meaningfully grouped? MECE principle respected?
        - **orderingLogic**: Is the argument ordering logical? \
        (Chronological, by importance, or structurally justified.)
        - **completeness**: Were all essential points from the original text captured? \
        Nothing important omitted, nothing new invented.

        ## Match Quality Scale
        - **high**: Valid pyramid with clear grouping, even if it differs from the answer key.
        - **partial**: Some structural effort but grouping or governing thought is weak.
        - **low**: No recognisable pyramid structure, or essential content missing/invented.
        """
    }

    private func spotTheGapRubric(language: String) -> String {
        if language == "de" {
            return """
            # Bewertungskriterien: Finde die Lücke

            Bewerte, ob der Lernende den strukturellen Fehler im Text korrekt identifiziert hat. \
            Der Fehlertyp ist wichtiger als die exakte Formulierung.

            ## Dimensionen (jeweils 0–3)
            - **flawIdentification**: Hat der Lernende den richtigen Fehlertyp erkannt? \
            (z.B. Zirkelschluss, falsches Dilemma, Non Sequitur, fehlende Stütze)
            - **locationAccuracy**: Hat der Lernende den Fehler an der richtigen Stelle im Text lokalisiert?
            - **explanationClarity**: Ist die Erklärung des Fehlers klar und nachvollziehbar?

            ## Bewertungsmaßstab
            - **high**: Richtiger Fehlertyp, richtige Stelle, klare Erklärung.
            - **partial**: Richtiger Fehlertyp aber falsche Stelle, oder richtige Stelle aber falsche Erklärung.
            - **low**: Falscher Fehlertyp, oder kein struktureller Fehler identifiziert.
            """
        }
        return """
        # Evaluation Criteria: Spot the Gap

        Evaluate whether the learner correctly identified the structural flaw in the text. \
        The flaw type matters more than the exact wording of the identification.

        ## Dimensions (0–3 each)
        - **flawIdentification**: Did the learner identify the correct flaw type? \
        (e.g. circular reasoning, false dichotomy, non sequitur, missing support)
        - **locationAccuracy**: Did the learner locate the flaw in the right part of the text?
        - **explanationClarity**: Is the explanation of the flaw clear and understandable?

        ## Match Quality Scale
        - **high**: Correct flaw type, correct location, clear explanation.
        - **partial**: Correct flaw type but wrong location, or correct location but wrong explanation.
        - **low**: Wrong flaw type, or no structural flaw identified.
        """
    }

    private func decodeAndRebuildRubric(language: String) -> String {
        if language == "de" {
            return """
            # Bewertungskriterien: Entschlüsseln und Neubauen

            Bewerte, wie gut der Lernende die Struktur des Textes erkannt hat \
            und ob die Neuformulierung eine strukturelle Verbesserung darstellt.

            ## Dimensionen (jeweils 0–3)
            - **governingThoughtAccuracy**: Hat der Lernende den Kerngedanken korrekt identifiziert?
            - **supportIdentification**: Hat der Lernende die wichtigsten Stützgruppen erkannt?
            - **structuralImprovement**: Ist die Neuformulierung strukturell besser als das Original? \
            (Klare Führung mit dem Kerngedanken, logische Gruppierung der Stützen)

            ## Bewertungsmaßstab
            - **high**: Kerngedanke korrekt, Stützen erkannt, deutliche strukturelle Verbesserung.
            - **partial**: Kerngedanke teilweise korrekt oder einige Stützen übersehen, moderate Verbesserung.
            - **low**: Kerngedanke falsch oder keine strukturelle Verbesserung gegenüber dem Original.
            """
        }
        return """
        # Evaluation Criteria: Decode and Rebuild

        Evaluate how well the learner extracted the text's structure \
        and whether their rewrite represents a structural improvement.

        ## Dimensions (0–3 each)
        - **governingThoughtAccuracy**: Did the learner correctly identify the governing thought?
        - **supportIdentification**: Did the learner identify the key support groups?
        - **structuralImprovement**: Is the rewrite structurally better than the original? \
        (Clear lead with governing thought, logical grouping of supports)

        ## Match Quality Scale
        - **high**: Correct governing thought, supports identified, clear structural improvement.
        - **partial**: Governing thought partially correct or some supports missed, moderate improvement.
        - **low**: Wrong governing thought or no structural improvement over the original.
        """
    }

    // MARK: - Output Format

    private func outputFormatBlock(for sessionType: ComparisonSessionType, language: String) -> String {
        let dimensions = dimensionNames(for: sessionType)
        let dimensionJSON = dimensions.map { "\"\($0)\": <0-3>" }.joined(separator: ", ")

        if language == "de" {
            return """
            # Ausgabeformat

            Antworte mit genau zwei Teilen:

            1. **Sichtbares Feedback**: Barbaras Antwort an den Lernenden. Direkt, strukturfokussiert, \
            in Barbaras Stimme. Maximal 3-4 Sätze.

            2. **Versteckte Metadaten**: Ein einzelner HTML-Kommentar am Ende:

            ```
            <!-- COMPARISON_META: {"matchQuality":"high|partial|low","dimensionScores":{\(dimensionJSON)},"mood":"<mood>","progressionSignal":"<signal>","sessionPhase":"evaluation","feedbackFocus":"<focus>","language":"de"} -->
            ```

            Gültige Stimmungen: attentive, skeptical, approving, waiting, proud, evaluating, teaching, disappointed
            Gültige Signale: none, improving, struggling, ready_for_level_up, regression
            """
        }
        return """
        # Output Format

        Respond with exactly two parts:

        1. **Visible feedback**: Barbara's response to the learner. Direct, structure-focused, \
        in Barbara's voice. Maximum 3-4 sentences.

        2. **Hidden metadata**: A single HTML comment at the end:

        ```
        <!-- COMPARISON_META: {"matchQuality":"high|partial|low","dimensionScores":{\(dimensionJSON)},"mood":"<mood>","progressionSignal":"<signal>","sessionPhase":"evaluation","feedbackFocus":"<focus>","language":"en"} -->
        ```

        Valid moods: attentive, skeptical, approving, waiting, proud, evaluating, teaching, disappointed
        Valid signals: none, improving, struggling, ready_for_level_up, regression
        """
    }

    private func dimensionNames(for sessionType: ComparisonSessionType) -> [String] {
        switch sessionType {
        case .findThePoint:
            return ["governingThoughtAccuracy", "specificity", "supportAwareness"]
        case .fixThisMess:
            return ["pyramidValidity", "groupingQuality", "orderingLogic", "completeness"]
        case .spotTheGap:
            return ["flawIdentification", "locationAccuracy", "explanationClarity"]
        case .decodeAndRebuild:
            return ["governingThoughtAccuracy", "supportIdentification", "structuralImprovement"]
        }
    }

    // MARK: - Answer Key Formatting

    private func formatAnswerKey(_ key: AnswerKey) -> String {
        var parts: [String] = []
        parts.append("**Governing Thought**: \(key.governingThought)")

        for (index, group) in key.supports.enumerated() {
            let evidence = group.evidence.map { "  - \($0)" }.joined(separator: "\n")
            parts.append("**Support \(index + 1): \(group.label)**\n\(evidence)")
        }

        parts.append("**Structural Assessment**: \(key.structuralAssessment)")

        if let flaw = key.structuralFlaw {
            parts.append("**Structural Flaw**: [\(flaw.type)] \(flaw.description) (at \(flaw.location))")
        }

        if let restructure = key.proposedRestructure {
            parts.append("**Proposed Restructure**: \(restructure)")
        }

        return parts.joined(separator: "\n\n")
    }
}
