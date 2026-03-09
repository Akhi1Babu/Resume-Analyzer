import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/resume_model.dart';
import '../models/analysis_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class ResumeService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<AnalysisModel> processAndAnalyzeResume(
    Uint8List fileBytes,
    String fileName, {
    String? jobDescription,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    // BYPASS STORAGE: We'll skip uploading the actual PDF file to the cloud.
    // Instead, we will extract the text entirely in your browser's memory!
    final String localPlaceholderUrl = 'local://in-memory/$fileName';

    // 1. Extract text logic using syncfusion entirely in memory!
    final text = await _extractTextFromPdf(fileBytes);

    // 2. Save resume metadata to Firestore (Without needing Storage permissions)
    final resumeRef = _firestore.collection('resumes').doc();
    final resumeModel = ResumeModel(
      id: resumeRef.id,
      userId: user.uid,
      fileUrl: localPlaceholderUrl,
      uploadDate: Timestamp.now(),
    );
    await resumeRef.set(resumeModel.toJson());

    // 3. Analyze Text
    final analysis = await _performScoring(
      text,
      localPlaceholderUrl,
      user.uid,
      jobDescription: jobDescription,
    );

    // 5. Save Analysis Result
    final analysisRef = _firestore.collection('analysis').doc();
    final finalAnalysis = AnalysisModel(
      id: analysisRef.id,
      userId: analysis.userId,
      resumeUrl: analysis.resumeUrl,
      score: analysis.score,
      suggestions: analysis.suggestions,
      timestamp: analysis.timestamp,
      detectedSections: analysis.detectedSections,
      jobMatchPercentage: analysis.jobMatchPercentage,
      missingKeywords: analysis.missingKeywords,
      rewrittenBullets: analysis.rewrittenBullets,
      categoryScores: analysis.categoryScores,
      rewrittenResumeText: analysis.rewrittenResumeText,
      rewrittenResumeLatex: analysis.rewrittenResumeLatex,
    );

    await analysisRef.set(finalAnalysis.toJson());

    return finalAnalysis;
  }

  /// Given the original resume plain text and a job description,
  /// generates a fully rewritten LaTeX source targeting that JD.
  Future<String> tailorResumeToJob({
    required String resumeText,
    required String jobDescription,
  }) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

    if (apiKey.isEmpty) throw Exception('No API Key configured.');

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt =
        '''
You are an expert resume writer and ATS optimization specialist.
You are given a candidate's resume and a job description.
Your task is to rewrite the entire resume to perfectly match the job description.

RULES:
- Incorporate ALL important keywords, skills, and tools mentioned in the job description naturally into the resume.
- Rewrite bullet points to use strong action verbs and quantifiable metrics.
- Keep the candidate's real experience, names, dates and education — do NOT fabricate facts.
- Output ONLY a JSON object with a single key: "latex"
- The "latex" value must be a complete, compile-ready LaTeX source code using the Harshibar ATS template structure below.
- MUST ESCAPE ALL NEWLINES AS \\n AND DOUBLE QUOTES AS \\" SO THE JSON REMAINS PERFECTLY VALID.

LaTeX Template Structure to follow:
\\documentclass[letterpaper,11pt]{article}
\\usepackage[empty]{fullpage}
\\usepackage{titlesec}
\\usepackage[usenames,dvipsnames]{color}
\\usepackage{enumitem}
\\usepackage[hidelinks]{hyperref}
\\usepackage{fancyhdr}
\\usepackage{tabularx}
\\usepackage{tgheros}
\\renewcommand*\\familydefault{\\sfdefault}
\\usepackage[T1]{fontenc}
\\definecolor{light-grey}{gray}{0.83}
\\definecolor{dark-grey}{gray}{0.3}
\\pagestyle{fancy}
\\fancyhf{}
\\fancyfoot{}
\\renewcommand{\\headrulewidth}{0pt}
\\addtolength{\\oddsidemargin}{-0.5in}
\\addtolength{\\textwidth}{1in}
\\addtolength{\\topmargin}{-.5in}
\\addtolength{\\textheight}{1.0in}
\\titleformat{\\section}{\\bfseries \\vspace{2pt} \\raggedright \\large}{}{0em}{}[\\color{light-grey}{\\titlerule[2pt]} \\vspace{-4pt}]
\\newcommand{\\resumeItem}[1]{\\item\\small{{#1 \\vspace{-1pt}}}}
\\newcommand{\\resumeSubheading}[4]{\\vspace{-1pt}\\item\\begin{tabular*}{\\textwidth}[t]{l@{\\extracolsep{\\fill}}r}\\textbf{#1} & {\\color{dark-grey}\\small #2}\\vspace{1pt}\\\\ \\textit{#3} & {\\color{dark-grey} \\small #4}\\\\\\end{tabular*}\\vspace{-4pt}}
\\newcommand{\\resumeProjectHeading}[2]{\\item\\begin{tabular*}{\\textwidth}{l@{\\extracolsep{\\fill}}r}#1 & {\\color{dark-grey}} \\\\\\end{tabular*}\\vspace{-4pt}}
\\newcommand{\\resumeSubHeadingListStart}{\\begin{itemize}[leftmargin=0in, label={}]}
\\newcommand{\\resumeSubHeadingListEnd}{\\end{itemize}}
\\newcommand{\\resumeItemListStart}{\\begin{itemize}}
\\newcommand{\\resumeItemListEnd}{\\end{itemize}\\vspace{0pt}}
\\begin{document}
... (fill in all sections: HEADING, EXPERIENCE, EDUCATION, SKILLS, PROJECTS)
\\end{document}

Job Description:
$jobDescription

Candidate Resume Text:
$resumeText
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final responseText = response.text ?? '{}';

    final int startIndex = responseText.indexOf('{');
    final int endIndex = responseText.lastIndexOf('}');
    if (startIndex == -1 || endIndex == -1) {
      throw FormatException('No JSON found in tailor response');
    }

    final data = jsonDecode(responseText.substring(startIndex, endIndex + 1));
    final latex = data['latex'] as String? ?? '';
    if (latex.isEmpty) throw Exception('AI returned empty LaTeX code.');
    return latex;
  }

  Future<String> _extractTextFromPdf(Uint8List pdfBytes) async {
    try {
      final document = PdfDocument(inputBytes: pdfBytes);
      final extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();
      return text;
    } catch (e) {
      debugPrint("Error extracting text: $e");
      return "";
    }
  }

  Future<AnalysisModel> _performScoring(
    String text,
    String resumeUrl,
    String userId, {
    String? jobDescription,
  }) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY') {
      debugPrint("Fallback to local scoring: No API Key provided.");
      return _fallbackLocalScoring(
        text,
        resumeUrl,
        userId,
        jobDescription: jobDescription,
      );
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
      final hasJd = jobDescription != null && jobDescription.trim().isNotEmpty;
      final prompt =
          '''
You are a harsh, critical resume reviewer and career coach. Review the following resume text.
Mock the candidate if there are problems, missing sections, lack of experience, or poor formatting.
Be humorous but brutal in your suggestions.
${hasJd ? "Evaluate the resume against this Job Description:\n$jobDescription\n" : ""}
You must return your analysis strictly as a JSON object, with no markdown formatting or extra text.
The JSON object must have exactly this structure:
{
  "score": <integer between 0 and 100>,
  "suggestions": ["<mocking suggestion 1>", "<mocking suggestion 2>"],
  "detectedSections": {
    "Education": <boolean>,
    "Skills": <boolean>,
    "Projects": <boolean>,
    "Experience": <boolean>,
    "Achievements": <boolean>
  },
  "jobMatchPercentage": ${hasJd ? "<integer between 0 and 100>" : "null"},
  "missingKeywords": ${hasJd ? '["<missing keyword 1>", "<missing keyword 2>"]' : "[]"},
  "rewrittenBullets": [
     {"before": "<weak resume bullet>", "after": "<strong, metric-driven ATS-friendly rewrite>"},
     {"before": "<another weak bullet>", "after": "<strong rewrite>"},
     {"before": "<third weak bullet>", "after": "<strong rewrite>"}
  ],
  "categoryScores": {
    "Impact": <integer between 0 and 100>,
    "Brevity": <integer between 0 and 100>,
    "Action Verbs": <integer between 0 and 100>,
    "Formatting": <integer between 0 and 100>,
    "Skills": <integer between 0 and 100>
  },
  "rewrittenResumeText": "<string containing a fully rewritten, ATS-optimized version of the resume. Imitate standard resume sections: SUMMARY, EXPERIENCE, EDUCATION, SKILLS, PROJECTS. Under each heading, provide the content. For Experience/Projects/Education subheadings, use this EXACT format on a single line: 'Title/Role | Company/School | Location | Dates'. Then use standard bullet points starting with exactly '- '. Do not use markdown like asterisks. CRITICAL: MUST ESCAPE ALL NEWLINES AS \\n AND DOUBLE QUOTES AS \\\" SO THE JSON REMAINS VALID.>",
  "rewrittenResumeLatex": "<string containing a cohesive, fully rewritten, ATS-optimized version of the entire resume from top to bottom. CRITICAL: This MUST be a completely valid, compile-ready LaTeX source code document using the exact 'Harshibar / Jake\\'s Resume' ATS template structure. Do not use Markdown, only pure unescaped LaTeX code wrapped inside the JSON string. CRITICAL: MUST ESCAPE ALL NEWLINES AS \\n AND DOUBLE QUOTES AS \\\" SO THE JSON IN THIS FIELD REMAINS PERFECTLY VALID.>"
}

Resume Text:
$text
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text ?? '{}';

      // Advanced JSON extraction: locate the outermost { and }
      final int startIndex = responseText.indexOf('{');
      final int endIndex = responseText.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1) {
        throw FormatException('No JSON found in response');
      }

      final cleanJson = responseText.substring(startIndex, endIndex + 1);
      final data = jsonDecode(cleanJson);

      return AnalysisModel(
        id: '', // Will be assigned before save
        userId: userId,
        resumeUrl: resumeUrl,
        score: data['score'] ?? 0,
        suggestions: List<String>.from(data['suggestions'] ?? []),
        timestamp: Timestamp.now(),
        detectedSections: Map<String, bool>.from(
          data['detectedSections'] ??
              {
                'Education': false,
                'Skills': false,
                'Projects': false,
                'Experience': false,
                'Achievements': false,
              },
        ),
        jobMatchPercentage: data['jobMatchPercentage'],
        missingKeywords: List<String>.from(data['missingKeywords'] ?? []),
        rewrittenBullets:
            (data['rewrittenBullets'] as List<dynamic>?)
                ?.map(
                  (e) => RewrittenBullet.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
        categoryScores: Map<String, int>.from(data['categoryScores'] ?? {}),
        rewrittenResumeText:
            data['rewrittenResumeText'] ??
            'DEBUG STRING: The AI completely ignored the instruction to generate rewrittenResumeText! Check the JSON schema.',
        rewrittenResumeLatex: data['rewrittenResumeLatex'],
      );
    } catch (e, stack) {
      debugPrint("AI engine error occurred: $e\n$stack");
      return _fallbackLocalScoring(
        text,
        resumeUrl,
        userId,
        jobDescription: jobDescription,
      );
    }
  }

  AnalysisModel _fallbackLocalScoring(
    String text,
    String resumeUrl,
    String userId, {
    String? jobDescription,
  }) {
    final lowerText = text.toLowerCase();

    bool hasEducation =
        lowerText.contains('education') ||
        lowerText.contains('university') ||
        lowerText.contains('btech');
    bool hasSkills =
        lowerText.contains('skills') || lowerText.contains('technologies');
    bool hasProjects = lowerText.contains('projects');
    bool hasExperience =
        lowerText.contains('experience') ||
        lowerText.contains('work history') ||
        lowerText.contains('internship');
    bool hasAchievements =
        lowerText.contains('achievements') || lowerText.contains('awards');

    int score = 0;
    List<String> suggestions = [];

    if (hasEducation)
      score += 20;
    else
      suggestions.add('Add an Education section.');
    if (hasSkills)
      score += 20;
    else
      suggestions.add(
        'Add a Skills section highlighting your technical abilities.',
      );
    if (hasProjects)
      score += 20;
    else
      suggestions.add(
        'Include a Projects section to show practical applications of your skills.',
      );
    if (hasExperience)
      score += 20;
    else
      suggestions.add('Add work experience or internships.');
    if (hasAchievements)
      score += 20;
    else
      suggestions.add(
        'Include an Achievements or Awards section to stand out.',
      );

    return AnalysisModel(
      id: '', // Will be assigned before save
      userId: userId,
      resumeUrl: resumeUrl,
      score: score,
      suggestions: suggestions,
      timestamp: Timestamp.now(),
      detectedSections: {
        'Education': hasEducation,
        'Skills': hasSkills,
        'Projects': hasProjects,
        'Experience': hasExperience,
        'Achievements': hasAchievements,
      },
      jobMatchPercentage: jobDescription != null && jobDescription.isNotEmpty
          ? 50
          : null,
      missingKeywords: jobDescription != null && jobDescription.isNotEmpty
          ? ['Example Skill']
          : [],
      rewrittenBullets: [], // local doesn't rewrite bullets
      categoryScores: {
        'Impact': score,
        'Brevity': 50,
        'Action Verbs': 50,
        'Formatting': 50,
        'Skills': hasSkills ? 100 : 0,
      },
      rewrittenResumeText:
          'DEBUG STRING: LOCAL FALLBACK TRIGGERED. The AI threw an error, or the API key failed. Please check your console logs.',
    );
  }
}
