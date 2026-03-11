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

  /// Generates a structured list of interview questions from resume text.
  /// Returns a JSON string: { "categories": [ { "name": ..., "questions": [ { "q": ..., "tip": ... } ] } ] }
  Future<Map<String, dynamic>> generateInterviewQuestions({
    required String resumeText,
    String? jobTitle,
  }) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) throw Exception('No API Key configured.');

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final title = jobTitle?.isNotEmpty == true
        ? jobTitle!
        : 'the role suggested by the resume';

    final prompt =
        '''
You are a senior technical recruiter and career coach.
Analyze the candidate\'s resume and generate a comprehensive set of interview questions
they are highly likely to face when applying for $title.

Output ONLY a JSON object with this exact structure (no markdown, no extra text):
{
  "categories": [
    {
      "name": "Behavioral & Soft Skills",
      "icon": "psychology",
      "color": "#FFB800",
      "questions": [
        { "q": "question text", "tip": "brief answer tip in 1-2 sentences" }
      ]
    },
    {
      "name": "Technical & Domain Skills",
      "icon": "code",
      "color": "#00FFC2",
      "questions": [...]
    },
    {
      "name": "Role-Specific Experience",
      "icon": "work",
      "color": "#7B2FFF",
      "questions": [...]
    },
    {
      "name": "Situational & Problem Solving",
      "icon": "lightbulb",
      "color": "#FF4949",
      "questions": [...]
    }
  ]
}

Rules:
- Generate 4-6 questions per category (total ~18-22 questions).
- Each question must be tailored to THIS candidate\'s specific resume.
- Tips must be concise and actionable (max 25 words).
- Base technical questions on the exact skills and technologies found in the resume.
- MUST ESCAPE ALL NEWLINES AS \\n AND DOUBLE QUOTES AS \\" SO JSON IS VALID.

Resume:
$resumeText
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1) throw FormatException('No JSON in response');

    return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
  }

  /// Generates a structured 30-day learning plan for a missing skill.
  Future<Map<String, dynamic>> generateSkillLearningPlan({
    required String skill,
    required String targetJobTitle,
    String? currentLevel, // beginner / intermediate / advanced
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
You are an expert learning coach and software skills mentor.
Create a detailed, structured 30-day learning plan for mastering "$skill"
so the candidate can qualify for a "$targetJobTitle" role.
Current level: ${currentLevel ?? 'beginner'}.

Output ONLY valid JSON with this exact structure:
{
  "skill": "$skill",
  "totalDays": 30,
  "summary": "One sentence overview of the plan",
  "weeks": [
    {
      "week": 1,
      "theme": "Foundations",
      "days": "Day 1-7",
      "goal": "What will be mastered",
      "tasks": [
        "Specific task or resource",
        "Specific task or resource"
      ],
      "milestone": "What you can do by end of week"
    },
    { "week": 2, ... },
    { "week": 3, ... },
    { "week": 4, ... }
  ],
  "resources": [
    { "type": "Course", "name": "Resource name", "url": "URL or platform", "free": true },
    { "type": "Book", "name": "Book name", "url": "", "free": false },
    { "type": "Practice", "name": "Platform or exercise", "url": "", "free": true }
  ],
  "projectIdea": "A mini project to build and add to resume to prove this skill"
}

Rules:
- Be VERY specific with tasks (not vague like "learn the basics").
- Reference actual resources (YouTube channels, docs, frameworks, websites).
- The milestone must be concrete and testable.
- Escape all special characters for valid JSON.
''';

    final response = await model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1) throw FormatException('No JSON in response');
    return jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
  }

  /// Chat with the AI about the resume. Maintains a history list of messages.
  /// Returns the AI reply as a plain string.
  Future<String> chatWithResume({
    required String resumeText,
    required List<Map<String, String>>
    history, // [{role:'user'|'model', text:'...'}]
    required String userMessage,
  }) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) throw Exception('No API Key configured.');

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

    // Build content list — system context + history + new message
    final systemPrompt =
        '''
You are a helpful, friendly career coach AI assistant. 
The user is asking questions about their own resume (pasted below).
Answer questions clearly, directly, and with constructive advice.
Keep answers concise (3-5 sentences max unless a detailed breakdown is specifically asked).
Be conversational but professional. Use bullet points when listing items.

RESUME:
$resumeText
''';

    final contents = <Content>[];

    // System context as first user turn (Gemini doesn't have a system role)
    contents.add(Content.text(systemPrompt));

    // Prior conversation turns
    for (final msg in history) {
      if (msg['role'] == 'user') {
        contents.add(Content.text(msg['text'] ?? ''));
      } else {
        contents.add(Content.model([TextPart(msg['text'] ?? '')]));
      }
    }

    // New user message
    contents.add(Content.text(userMessage));

    final response = await model.generateContent(contents);
    return response.text?.trim() ?? 'Sorry, I could not generate a response.';
  }

  /// Conduct a voice-driven interview. Acts as a strict but fair technical interviewer.
  /// Maintains conversational history.
  Future<String> voiceInterviewTurn({
    required String resumeText,
    required List<Map<String, String>> history,
    required String userMessage,
  }) async {
    const apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) throw Exception('No API Key configured.');
    final systemInstructionString =
        '''
You are an expert technical recruiter conducting a live, voice-based conversational interview with the candidate.
The candidate's resume is below.
Rules for this interview:
1. Ask one direct, specific question at a time based on their experience or skills.
2. If this is the start of the interview (no history), greet them briefly and ask the first question.
3. If the user answers, give brief feedback (1-2 sentences) and then ask the NEXT logical question.
4. Keep all responses very short and spoken-word friendly (max 3-4 sentences total per turn).
5. DO NOT use markdown formatting like **bold** or bullet points, because this text will be read aloud by a text-to-speech engine. Use plain conversational English.

CANDIDATE RESUME:
$resumeText
''';

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(systemInstructionString),
    );

    final contents = <Content>[];

    for (final msg in history) {
      if (msg['role'] == 'user') {
        contents.add(Content.text(msg['text'] ?? ''));
      } else {
        contents.add(Content.model([TextPart(msg['text'] ?? '')]));
      }
    }

    // Handle empty start message correctly if needed
    if (userMessage.isNotEmpty) {
      contents.add(Content.text(userMessage));
    } else if (history.isEmpty) {
      contents.add(Content.text("Hello, I am ready to start the interview."));
    }

    try {
      final response = await model.generateContent(contents);
      return response.text?.trim() ??
          'Sorry, I could not hear you. Let us try again.';
    } catch (e) {
      debugPrint('voiceInterviewTurn error: $e');
      rethrow;
    }
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
    debugPrint(
      '>>> GEMINI_API_KEY loaded: "${apiKey.isEmpty ? "EMPTY!" : apiKey.substring(0, 8) + "..."}',
    );

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
