import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:daily_planner/models/message_model.dart';
import 'package:daily_planner/config/environment_config.dart';
import 'package:daily_planner/utils/error_handler.dart';

// ============================================================================
// EXAM DATA MODELS (FROM DOMAIN.YML INTEGRATION)
// ============================================================================

/// Exam types supported by the chatbot
enum ExamType {
  cds,
  nda,
  banking,
  clat,
  ca,
  hssc,
  jee,
  neet,
  upsc,
  cat,
  sscCgl,
}

/// Study schedule types
enum ScheduleType {
  dayWorker,
  nightOwl,
  overview,
}

/// Exam data model with timetables and information
class ExamData {
  final ExamType examType;
  final String overview;
  final String dayWorkerTimetable;
  final String nightOwlTimetable;
  final List<String> keyTopics;
  final List<String> strategies;
  final Map<String, dynamic> additionalInfo;

  const ExamData({
    required this.examType,
    required this.overview,
    required this.dayWorkerTimetable,
    required this.nightOwlTimetable,
    required this.keyTopics,
    required this.strategies,
    required this.additionalInfo,
  });

  factory ExamData.fromJson(Map<String, dynamic> json) {
    return ExamData(
      examType: ExamType.values.firstWhere(
            (e) => e.toString().split('.').last == json['examType'],
        orElse: () => ExamType.hssc,
      ),
      overview: json['overview'] ?? '',
      dayWorkerTimetable: json['dayWorkerTimetable'] ?? '',
      nightOwlTimetable: json['nightOwlTimetable'] ?? '',
      keyTopics: List<String>.from(json['keyTopics'] ?? []),
      strategies: List<String>.from(json['strategies'] ?? []),
      additionalInfo: Map<String, dynamic>.from(json['additionalInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'examType': examType.toString().split('.').last,
      'overview': overview,
      'dayWorkerTimetable': dayWorkerTimetable,
      'nightOwlTimetable': nightOwlTimetable,
      'keyTopics': keyTopics,
      'strategies': strategies,
      'additionalInfo': additionalInfo,
    };
  }
}

// ============================================================================
// CHATBOT SERVICE IMPLEMENTATION (ENHANCED WITH EXAM DATA)
// ============================================================================

/// Service for handling chatbot interactions using Groq API
/// Provides AI-powered assistance for productivity and task management
/// ENHANCED: Now includes exam-related data and specialized responses
class ChatbotService {
  static const String _defaultModel = 'llama3-70b-8192';
  static const int _maxTokens = 2048;
  static const double _temperature = 0.7;
  static const Duration _timeoutDuration = Duration(seconds: 30);

  final String _apiKey;
  final String _baseUrl;
  final String _model;
  late final http.Client _httpClient;

  String? _systemPrompt;
  final List<Message> _conversationHistory = [];
  bool _isInitialized = false;

  // ADDED: Exam data storage
  final Map<ExamType, ExamData> _examData = {};
  bool _examDataLoaded = false;

  // ============================================================================
  // CONSTRUCTOR
  // ============================================================================

  ChatbotService({
    String? apiKey,
    String? baseUrl,
    String? model,
    http.Client? httpClient,
  }) : _apiKey = apiKey ?? EnvironmentConfig.groqApiKey,
        _baseUrl = baseUrl ?? EnvironmentConfig.groqBaseUrl,
        _model = model ?? EnvironmentConfig.groqModel,
        _httpClient = httpClient ?? http.Client();

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize the chatbot service with configuration and exam data
  Future<void> initialize({String? apiKey}) async {
    if (_isInitialized) return;

    try {
      // Use provided API key or fallback to instance key
      final effectiveApiKey = apiKey ?? _apiKey;

      // Validate configuration
      if (effectiveApiKey.isEmpty || effectiveApiKey == 'your_groq_api_key_here') {
        throw ChatbotException('Groq API key is not configured');
      }

      if (!_isValidUrl(_baseUrl)) {
        throw ChatbotException('Invalid Groq base URL: $_baseUrl');
      }

      // Set default system prompt if none provided
      _systemPrompt ??= _getDefaultSystemPrompt();

      // ADDED: Load exam data from domain.yml
      await _loadExamData();

      _isInitialized = true;

      if (kDebugMode) {
        print('ChatbotService: Initialized successfully');
        print('  Model: $_model');
        print('  Base URL: $_baseUrl');
        print('  Exam data loaded: $_examDataLoaded');
        print('  Available exams: ${_examData.keys.length}');
      }
    } catch (e) {
      ErrorHandler.handleError(e, 'ChatbotService initialization failed');
      rethrow;
    }
  }

  /// ADDED: Load exam data from domain.yml integrated data
  Future<void> _loadExamData() async {
    try {
      // Load hardcoded exam data based on domain.yml structure
      _examData[ExamType.cds] = ExamData(
        examType: ExamType.cds,
        overview: '''**CDS Exam Overview:**
The Combined Defence Services (CDS) exam is conducted by UPSC for admission into the Indian Military Academy (IMA), Indian Naval Academy (INA), Air Force Academy (AFA), and Officers Training Academy (OTA).  
For IMA, INA, and AFA, the written exam consists of:
• **English:** 100 marks, 2 hours (reading comprehension, grammar, vocabulary).  
• **General Knowledge:** 100 marks, 2 hours (current affairs, history, geography, polity, economy, general science).  
• **Elementary Mathematics:** 100 marks, 2 hours (arithmetic, algebra, geometry, mensuration, trigonometry, statistics).  
For OTA, only the English and General Knowledge papers are included.  
This exam is followed by an SSB interview (300 marks over 5 days). Key principles include balancing all subjects, revisiting NCERT fundamentals, staying updated on current affairs, and consistent mock tests.''',
        dayWorkerTimetable: '''**CDS Day Worker Timetable (Self-Study):**

**Morning:**
- **6:00 AM - 6:30 AM:** Wake up, freshen up, and perform light meditation or stretching.
- **6:30 AM - 7:30 AM:** Physical Fitness: Engage in running, jogging, light cardio, and bodyweight exercises to build endurance.
- **7:30 AM - 8:30 AM:** Breakfast & Short Break.

**Mid-Morning:**
- **8:30 AM - 10:30 AM:** English Language: Read newspaper editorials (e.g., from The Hindu or Indian Express) to boost comprehension and vocabulary; practice 2–3 reading comprehension passages; revise key grammar rules.
- **10:30 AM - 11:00 AM:** Short Break.
- **11:00 AM - 1:00 PM:** General Knowledge – Current Affairs & Static GS: Read a national daily; focus on national, international, and defense news; study a specific topic (e.g., aspects of Indian History or Polity) and take concise notes.

**Afternoon:**
- **1:00 PM - 2:00 PM:** Lunch & Relaxation.
- **2:00 PM - 3:30 PM:** Elementary Mathematics (for IMA/INA/AFA targets): Learn a new topic (e.g., Mensuration, Trigonometry, or Algebra) and practice 20–30 related problems. (If you're targeting OTA, use this slot for additional GK or English practice.)
- **3:30 PM - 4:00 PM:** Short Break/Tea.

**Evening:**
- **4:00 PM - 6:00 PM:** General Knowledge – Core Subjects (Rotation): Alternate between subjects such as Physics/Chemistry/Biology on certain days and Indian Polity/Economy or History/Geography on others. Make brief notes for future revision.
- **6:00 PM - 7:30 PM:** Leisure / Personality Development: Engage in hobbies, read non-fiction, or practice public speaking to enhance your officer-like qualities.
- **7:30 PM - 8:30 PM:** Dinner & Family Time.

**Night:**
- **8:30 PM - 10:00 PM:** Mixed Practice/Weak Area Focus & Daily Revision: Solve 20–30 mixed MCQs from all sections; review key concepts, formulas, and vocabulary learned during the day.
- **10:00 PM onwards:** Wind down, plan for the next day, and ensure 7–8 hours of quality sleep.''',
        nightOwlTimetable: '''**CDS Night Owl Timetable (With Coaching):**

**Late Morning:**
- **10:00 AM - 11:00 AM:** Wake up, freshen up, and have a light breakfast.
- **11:00 AM - 12:00 PM:** Physical Fitness (or review previous coaching notes, if fitness was done earlier).

**Early Afternoon:**
- **12:00 PM - 1:00 PM:** Review the previous day's coaching notes or engage in light current affairs reading.
- **1:00 PM - 2:00 PM:** Lunch & Preparation for Coaching.

**Afternoon:**
- **2:00 PM - 6:00 PM:** Attend coaching classes covering core subjects like English, General Knowledge, and Mathematics (if applicable).

**Early Evening:**
- **6:00 PM - 7:00 PM:** Break & Dinner.

**Evening & Night Sessions:**
- **7:00 PM - 9:30 PM:** Self-Study Session 1 (Peak Focus): Immediately practice and revise topics from coaching—for example, intensive problem-solving in Mathematics or targeted English exercises.
- **9:30 PM - 10:00 PM:** Short Break.
- **10:00 PM - 12:30 AM:** Self-Study Session 2 (Peak Focus): Focus on a different subject such as General Knowledge—engage in detailed reading and note-making, or commit to advanced English exercises.
- **12:30 AM - 1:30 AM:** Current Affairs/Vocabulary Revision: Take a deep dive into national/international current events and review crucial facts.
- **1:30 AM - 2:00 AM:** Plan for the next day and wind down.
- **2:00 AM onwards:** Sleep (aim for 7–8 hours).''',
        keyTopics: [
          'English Comprehension',
          'General Knowledge',
          'Elementary Mathematics',
          'Current Affairs',
          'SSB Preparation',
        ],
        strategies: [
          'Balance all three subjects equally',
          'Focus on NCERT fundamentals',
          'Daily current affairs updates',
          'Regular mock tests',
          'Physical fitness for SSB',
        ],
        additionalInfo: {
          'duration': '2.5 hours each paper',
          'totalMarks': '300 (100 each)',
          'negativeMarking': 'Yes',
          'ssbDuration': '5 days',
        },
      );

      _examData[ExamType.banking] = ExamData(
        examType: ExamType.banking,
        overview: '''**Banking Exams Study Timetable Overview:**
Banking exams like IBPS PO/Clerk, SBI PO/Clerk, and RBI Grade B test Reasoning, Quantitative Aptitude, English Language, and General Awareness (with a focus on Banking and Computer Aptitude). Speed, accuracy, and a solid grasp of fundamentals—backed by daily current affairs—are crucial for success.''',
        dayWorkerTimetable: '''**Banking Exams Day Worker Timetable:**
- **6:00 AM - 6:30 AM:** Wake up, freshen up, and do a light exercise.
- **6:30 AM - 7:30 AM:** Current Affairs: Read the newspaper/online sources and make concise notes.
- **7:30 AM - 8:30 AM:** Breakfast & Short Break.
- **8:30 AM - 10:30 AM:** Quantitative Aptitude: Focus on 1–2 topics (e.g., Simplification & Approximation, Data Interpretation). Practice 30–40 problems.
- **10:30 AM - 11:00 AM:** Take a short break.
- **11:00 AM - 1:00 PM:** Reasoning Ability: Practice puzzles, seating arrangements, and syllogism.
- **1:00 PM - 2:00 PM:** Lunch & Relaxation.
- **2:00 PM - 3:30 PM:** English Language: Work on grammar rules, build vocabulary (10–15 new words), and practice reading comprehension.
- **3:30 PM - 4:00 PM:** Short Break/Tea.
- **4:00 PM - 5:30 PM:** Banking/Static GK: Study topics such as RBI functions and types of banks.
- **5:30 PM - 7:00 PM:** Engage in physical activity or leisure.
- **7:00 PM - 8:00 PM:** Dinner & Family Time.
- **8:00 PM - 9:30 PM:** Daily Review & Practice: Solve mini quizzes from each subject; quickly revise the day's topics.
- **9:30 PM - 10:00 PM:** Plan for the next day and wind down.
- **10:00 PM onwards:** Sleep (aim for 7–8 hours).''',
        nightOwlTimetable: '''**Banking Exams Night Owl Timetable:**
- **10:00 AM - 11:00 AM:** Wake up, freshen up, and have a light breakfast.
- **11:00 AM - 1:00 PM:** Review previous coaching notes; attempt simple puzzles or data interpretation sets.
- **1:00 PM - 2:00 PM:** Lunch & Preparation for Coaching.
- **2:00 PM - 7:00 PM:** Attend coaching classes (covering Quantitative Aptitude, Reasoning, and English).
- **7:00 PM - 8:00 PM:** Dinner & Short Break.
- **8:00 PM - 10:30 PM:** Self-Study Session 1 (Peak Focus): Practice concepts taught in coaching with 50+ problems.
- **10:30 PM - 11:00 PM:** Short Break.
- **11:00 PM - 1:30 AM:** Self-Study Session 2 (Peak Focus): Focus on General Awareness (banking topics and current affairs) or further English practice.
- **1:30 AM - 2:30 AM:** Mixed Practice/Revision: Solve mixed problems and practice quick calculations.
- **2:30 AM - 3:00 AM:** Plan for the next day and wind down.
- **3:00 AM onwards:** Sleep.''',
        keyTopics: [
          'Quantitative Aptitude',
          'Reasoning Ability',
          'English Language',
          'General Awareness',
          'Banking Knowledge',
          'Computer Aptitude',
        ],
        strategies: [
          'Daily current affairs reading',
          'Speed and accuracy focus',
          'Banking domain knowledge',
          'Mock test practice',
          'Time management',
        ],
        additionalInfo: {
          'exams': ['IBPS PO', 'IBPS Clerk', 'SBI PO', 'SBI Clerk', 'RBI Grade B'],
          'pattern': 'Online MCQ',
          'levels': 'Prelims + Mains + Interview',
        },
      );

      _examData[ExamType.clat] = ExamData(
        examType: ExamType.clat,
        overview: '''**CLAT Exam Study Timetable Overview:**
CLAT tests your proficiency in English, Current Affairs & General Knowledge, Legal Reasoning, Logical Reasoning, and Quantitative Techniques. Success demands speed, critical reading, and strong logical analysis.''',
        dayWorkerTimetable: '''**CLAT Day Worker Timetable:**
- **6:00 AM - 6:30 AM:** Wake up, freshen up, and do light exercise.
- **6:30 AM - 7:30 AM:** Current Affairs: Read newspapers (with editorials and legal news) and make concise notes.
- **7:30 AM - 8:30 AM:** Breakfast & Short Break.
- **8:30 AM - 10:30 AM:** English Language: Practice reading comprehension (2–3 passages) and work on vocabulary building.
- **10:30 AM - 11:00 AM:** Short Break.
- **11:00 AM - 1:30 PM:** Legal Reasoning: Understand legal principles and practice passages based on recent judgments.
- **1:30 PM - 2:30 PM:** Lunch & Relaxation.
- **2:30 PM - 4:30 PM:** Logical Reasoning: Practice puzzles, syllogisms, and critical reasoning exercises.
- **4:30 PM - 5:00 PM:** Short Break/Tea.
- **5:00 PM - 6:30 PM:** Quantitative Techniques: Practice data interpretation and arithmetic problems.
- **6:30 PM - 7:30 PM:** Physical Activity/Leisure.
- **7:30 PM - 8:30 PM:** Dinner & Family Time.
- **8:30 PM - 9:30 PM:** Daily Revision: Recap legal principles, logical reasoning tricks, and current affairs.
- **9:30 PM - 10:00 PM:** Plan for next day and wind down.
- **10:00 PM:** Sleep.''',
        nightOwlTimetable: '''**CLAT Night Owl Timetable:**
- **10:00 AM - 11:00 AM:** Wake up, freshen up, and have a light breakfast.
- **11:00 AM - 1:00 PM:** Review coaching notes; engage in light English reading.
- **1:00 PM - 2:00 PM:** Lunch & Preparation for Coaching.
- **2:00 PM - 7:00 PM:** Attend coaching classes (covering Legal, Logical, English, and Quantitative sections).
- **7:00 PM - 8:00 PM:** Dinner & Short Break.
- **8:00 PM - 10:30 PM:** Self-Study Session 1 (Peak Focus): Practice Legal Reasoning and CLAT passages.
- **10:30 PM - 11:00 PM:** Short Break.
- **11:00 PM - 1:30 AM:** Self-Study Session 2 (Peak Focus): Focus on Logical Reasoning puzzles or quantitative practice.
- **1:30 AM - 2:30 AM:** Deep dive into Current Affairs and further English practice.
- **2:30 AM - 3:00 AM:** Plan for next day and wind down.
- **3:00 AM:** Sleep.''',
        keyTopics: [
          'English Language',
          'Current Affairs & GK',
          'Legal Reasoning',
          'Logical Reasoning',
          'Quantitative Techniques',
        ],
        strategies: [
          'Speed reading',
          'Critical analysis',
          'Legal principles understanding',
          'Current affairs focus',
          'Mock test practice',
        ],
        additionalInfo: {
          'duration': '2 hours',
          'questions': '120 MCQs',
          'sections': '5',
          'negativeMarking': 'Yes (-0.25)',
        },
      );

      _examData[ExamType.ca] = ExamData(
        examType: ExamType.ca,
        overview: '''**CA Exam Study Timetable Overview:**
For Chartered Accountant exams (Foundation/Intermediate/Final), key areas include Accounting, Business Laws, Business Mathematics & Statistics, and Business Economics & Business & Commercial Knowledge. Emphasis is on conceptual clarity, extensive numerical practice, and structured answer writing.''',
        dayWorkerTimetable: '''**CA Day Worker Timetable:**
- **6:00 AM - 6:30 AM:** Wake up, freshen up, and do light exercise.
- **6:30 AM - 8:00 AM:** Accounting: Study theory and solve basic problems (e.g., journal entries, ledger preparation).
- **8:00 AM - 9:00 AM:** Breakfast & Short Break.
- **9:00 AM - 11:00 AM:** Business Laws: Read and understand legal concepts; practice writing structured answers.
- **11:00 AM - 11:30 AM:** Short Break.
- **11:30 AM - 1:30 PM:** Mathematics & Statistics: Practice numerical problems and revise key formulas.
- **1:30 PM - 2:30 PM:** Lunch & Relaxation.
- **2:30 PM - 4:30 PM:** Economics & BCK: Study theory, understand key concepts, and attempt MCQs.
- **4:30 PM - 5:00 PM:** Short Break/Tea.
- **5:00 PM - 7:00 PM:** Problem Solving/Revision: Focus on revising topics in Accounting and Mathematics or revisit difficult Law concepts.
- **7:00 PM - 8:00 PM:** Physical Activity/Leisure.
- **8:00 PM - 9:00 PM:** Dinner & Family Time.
- **9:00 PM - 10:00 PM:** Daily Review: Recap topics, formulas, and legal sections.
- **10:00 PM:** Wind down and sleep (aim for 7–8 hours).''',
        nightOwlTimetable: '''**CA Night Owl Timetable:**
- **10:00 AM - 11:00 AM:** Wake up, freshen up, and have a light breakfast.
- **11:00 AM - 1:00 PM:** Review previous day's coaching notes or engage in additional theory reading (e.g., Business Laws or Economics).
- **1:00 PM - 2:00 PM:** Lunch & Preparation for Coaching.
- **2:00 PM - 7:00 PM:** Attend coaching classes covering Accounting, Law, Mathematics/Statistics, and Economics.
- **7:00 PM - 8:00 PM:** Dinner & Short Break.
- **8:00 PM - 10:30 PM:** Self-Study Session 1 (Peak Focus): Practice numerical problems from Accounting and Mathematics.
- **10:30 PM - 11:00 PM:** Short Break.
- **11:00 PM - 1:30 AM:** Self-Study Session 2 (Peak Focus): Focus on Business Laws (case studies, answer writing) or Economics (conceptual revision and MCQs).
- **1:30 AM - 2:30 AM:** Additional revision: Review key concepts or solve extra questions.
- **2:30 AM - 3:00 AM:** Plan for the next day and wind down.
- **3:00 AM:** Sleep.''',
        keyTopics: [
          'Accounting',
          'Business Laws',
          'Mathematics & Statistics',
          'Business Economics',
          'Business & Commercial Knowledge',
        ],
        strategies: [
          'Conceptual clarity',
          'Numerical practice',
          'Structured answer writing',
          'Regular revision',
          'Professional approach',
        ],
        additionalInfo: {
          'levels': ['Foundation', 'Intermediate', 'Final'],
          'pattern': 'Subjective + Objective',
          'articleship': 'Required',
        },
      );

      // Add more exam data for other exams...
      _examData[ExamType.hssc] = ExamData(
        examType: ExamType.hssc,
        overview: '''**HSSC Exams: General Overview**
Haryana Staff Selection Commission (HSSC) conducts exams for various Group B, C, and D posts in Haryana Government departments. The exam pattern and syllabus can vary significantly depending on the specific post.''',
        dayWorkerTimetable: '''**HSSC Day Worker Timetable (Self-Study Example):**
- **6:00 AM - 6:30 AM:** Wake up, freshen up, light exercise/meditation.
- **6:30 AM - 7:30 AM:** Current Affairs & Newspaper Reading (Focus on National, International, and Haryana News).
- **7:30 AM - 8:30 AM:** Breakfast & Short Break.
- **8:30 AM - 10:30 AM:** Quantitative Aptitude (Concept learning + Practice 30-40 problems from one topic).
- **10:30 AM - 11:00 AM:** Short Break.
- **11:00 AM - 1:00 PM:** Reasoning Ability (Practice different types of questions: puzzles, series, syllogisms etc.).
- **1:00 PM - 2:00 PM:** Lunch & Relaxation.
- **2:00 PM - 3:30 PM:** English Language (Grammar rules, Vocabulary building, 1-2 Reading Comprehension passages).
- **3:30 PM - 4:00 PM:** Short Break/Tea.
- **4:00 PM - 5:30 PM:** Haryana General Knowledge (History, Geography, Culture, Schemes).
- **5:30 PM - 6:30 PM:** Hindi Language (Grammar and Vocabulary).
- **6:30 PM - 7:30 PM:** Physical Activity/Leisure/Hobby.
- **7:30 PM - 8:30 PM:** Dinner & Family Time.
- **8:30 PM - 9:30 PM:** General Awareness (Static GK: History, Polity, Geography - other than Haryana) / Computer Knowledge (alternate days).
- **9:30 PM - 10:00 PM:** Daily Revision of all subjects covered & Plan for Next Day.
- **10:00 PM onwards:** Wind down & Sleep (aim for 7-8 hours).''',
        nightOwlTimetable: '''**HSSC Night Owl Timetable (Self-Study/Coaching Integration Example):**
- **10:00 AM - 11:00 AM:** Wake up, freshen up, and have a light breakfast.
- **11:00 AM - 1:00 PM:** Current Affairs Review (National, International, Haryana) & Light English/Hindi vocabulary practice.
- **1:00 PM - 2:00 PM:** Lunch & Preparation for Coaching (if any) or Deep Study Block.
- **2:00 PM - 6:00 PM:** Attend coaching classes OR Self-Study Block 1 (e.g., Quantitative Aptitude & Reasoning - 2 hours each with a short break).
- **6:00 PM - 7:00 PM:** Break & Dinner.
- **7:00 PM - 9:30 PM:** Self-Study Session 1 (Focus on core subjects from coaching or a challenging area like Haryana GK or a major GA topic).
- **9:30 PM - 10:00 PM:** Short Break.
- **10:00 PM - 12:30 AM:** Self-Study Session 2 (Deep dive into English & Hindi Language / Computer Knowledge / Revision of earlier topics).
- **12:30 AM - 2:00 AM:** Mixed Practice / Weak Area Focus (Solve MCQs from various sections, practice previous year questions, or revise formulas/notes).
- **2:00 AM - 2:30 AM:** Plan for the next day & Wind down.
- **2:30 AM onwards:** Sleep (aim for 7-8 hours).''',
        keyTopics: [
          'General Awareness',
          'Reasoning Ability',
          'Quantitative Aptitude',
          'English Language',
          'Hindi Language',
          'Haryana GK',
          'Computer Knowledge',
        ],
        strategies: [
          'Focus on Haryana-specific GK',
          'Regular current affairs',
          'Hindi language proficiency',
          'Mock test practice',
          'Previous year papers',
        ],
        additionalInfo: {
          'posts': 'Group B, C, D',
          'haryanaPriority': 'High weightage',
          'languages': 'Hindi important',
        },
      );

      _examDataLoaded = true;

      if (kDebugMode) {
        print('✅ Exam data loaded successfully: ${_examData.keys.length} exams');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to load exam data: $e');
      }
      _examDataLoaded = false;
    }
  }

  /// Initialize with a custom system prompt for productivity focus
  Future<void> initializeSystemPrompt(String systemPrompt) async {
    _systemPrompt = systemPrompt;
    await initialize();
  }

  // ============================================================================
  // CORE CHAT FUNCTIONALITY (ENHANCED WITH EXAM DATA)
  // ============================================================================

  /// Send a message to the chatbot and get a response
  Future<Message> sendMessage(String userMessage) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (userMessage.trim().isEmpty) {
      throw ChatbotException('Message cannot be empty');
    }

    try {
      // Create user message
      final userMsg = Message(
        content: userMessage.trim(),
        sender: MessageSender.user,
      );

      // Add to conversation history
      _conversationHistory.add(userMsg);

      // ADDED: Check if this is an exam-related query
      final examResponse = _getExamSpecificResponse(userMessage.trim());
      if (examResponse != null) {
        final examMessage = Message(
          content: examResponse,
          sender: MessageSender.bot,
        );
        _conversationHistory.add(examMessage);
        return examMessage;
      }

      // Prepare messages for API
      final messages = _prepareMessages();

      if (kDebugMode) {
        print('ChatbotService: Sending message to API...');
      }

      // Call Groq API
      final response = await _callGroqAPI(messages);

      // Create bot response message
      final botMessage = Message(
        content: response,
        sender: MessageSender.bot,
      );

      // Add to conversation history
      _conversationHistory.add(botMessage);

      if (kDebugMode) {
        print('ChatbotService: Received response from API');
      }

      return botMessage;
    } catch (e) {
      ErrorHandler.handleError(e, 'Failed to send message to chatbot');

      // Return an error message instead of crashing
      final errorMessage = Message(
        content: _getErrorResponseMessage(e),
        sender: MessageSender.bot,
      );

      _conversationHistory.add(errorMessage);
      return errorMessage;
    }
  }

  /// ADDED: Get exam-specific response from loaded data
  String? _getExamSpecificResponse(String userMessage) {
    if (!_examDataLoaded) return null;

    final lowerMessage = userMessage.toLowerCase();

    // Check for exam type mentions
    ExamType? detectedExam;
    ScheduleType? scheduleType;

    // Detect exam type
    if (lowerMessage.contains('cds')) {
      detectedExam = ExamType.cds;
    } else if (lowerMessage.contains('nda')) {
      detectedExam = ExamType.nda;
    } else if (lowerMessage.contains('banking') || lowerMessage.contains('ibps') || lowerMessage.contains('sbi')) {
      detectedExam = ExamType.banking;
    } else if (lowerMessage.contains('clat')) {
      detectedExam = ExamType.clat;
    } else if (lowerMessage.contains('ca') && (lowerMessage.contains('exam') || lowerMessage.contains('chartered'))) {
      detectedExam = ExamType.ca;
    } else if (lowerMessage.contains('hssc') || lowerMessage.contains('haryana')) {
      detectedExam = ExamType.hssc;
    } else if (lowerMessage.contains('jee')) {
      detectedExam = ExamType.jee;
    } else if (lowerMessage.contains('neet')) {
      detectedExam = ExamType.neet;
    } else if (lowerMessage.contains('upsc')) {
      detectedExam = ExamType.upsc;
    } else if (lowerMessage.contains('cat')) {
      detectedExam = ExamType.cat;
    } else if (lowerMessage.contains('ssc') && lowerMessage.contains('cgl')) {
      detectedExam = ExamType.sscCgl;
    }

    // Detect schedule type
    if (lowerMessage.contains('day worker') || lowerMessage.contains('dayworker') || lowerMessage.contains('morning')) {
      scheduleType = ScheduleType.dayWorker;
    } else if (lowerMessage.contains('night owl') || lowerMessage.contains('nightowl') || lowerMessage.contains('night')) {
      scheduleType = ScheduleType.nightOwl;
    } else if (lowerMessage.contains('overview') || lowerMessage.contains('about') || lowerMessage.contains('information')) {
      scheduleType = ScheduleType.overview;
    }

    // Check for general query patterns
    if (lowerMessage.contains('timetable') || lowerMessage.contains('schedule')) {
      if (detectedExam != null) {
        scheduleType ??= ScheduleType.dayWorker; // Default to day worker
      }
    }

    // Return appropriate response
    if (detectedExam != null && _examData.containsKey(detectedExam)) {
      final examData = _examData[detectedExam]!;

      switch (scheduleType) {
        case ScheduleType.overview:
          return examData.overview;
        case ScheduleType.dayWorker:
          return examData.dayWorkerTimetable;
        case ScheduleType.nightOwl:
          return examData.nightOwlTimetable;
        case null:
          return examData.overview; // Default to overview
      }
    }

    // Check for general strategy questions
    if (lowerMessage.contains('topper') && (lowerMessage.contains('strategy') || lowerMessage.contains('timetable'))) {
      return _getTopperStrategies();
    }

    if (lowerMessage.contains('study') && lowerMessage.contains('strategy')) {
      return _getGeneralStudyStrategies();
    }

    return null;
  }

  /// ADDED: Get topper strategies
  String _getTopperStrategies() {
    return '''**Universal Principles for Topper-Style Timetables & Study:**

1. **Conceptual Clarity over Rote Learning:** Toppers focus on understanding the 'why' behind concepts, not just memorizing facts. This helps in tackling application-based questions.

2. **Consistent Revision (Spaced Repetition):** They don't just study a topic once. Regular, spaced revisions (e.g., after 1 day, 1 week, 1 month) are crucial for long-term retention.

3. **Active Recall:** Instead of passively re-reading, toppers actively test themselves – by trying to recall information, teaching it to someone else, or doing practice questions without looking at notes.

4. **Extensive Problem-Solving & Practice:** For subjects like Math, Physics, Reasoning, they solve a vast variety of problems. For theory subjects, they practice answer writing or MCQs.

5. **Mock Tests & Rigorous Analysis:** Taking full-length mock tests in an exam-like environment is standard. More importantly, they spend significant time analyzing their performance – identifying weak areas, silly mistakes, and time management issues.

6. **Previous Year Questions (PYQs):** PYQs are a goldmine to understand exam patterns, important topics, and difficulty levels.

7. **Strategic Planning & Realistic Timetables:** They plan their studies well in advance, breaking down the syllabus into manageable daily/weekly targets, but also keep their timetables flexible.

8. **Prioritize Health & Well-being:** Adequate sleep (7-8 hours), proper nutrition, hydration, and short breaks for exercise or hobbies are non-negotiable. Burnout is a real threat.

9. **Minimize Distractions:** Focused study sessions are more productive. They find ways to minimize distractions from social media, etc., during study hours.

10. **Error Analysis & Improvement:** They maintain an error notebook or log to track mistakes and ensure they don't repeat them.

11. **Resource Management:** They stick to a few good quality resources rather than getting overwhelmed by too many books or materials.''';
  }

  /// ADDED: Get general study strategies
  String _getGeneralStudyStrategies() {
    return '''**Effective Study Strategies:**

**Time Management:**
• Pomodoro Technique: 25 minutes focused study + 5 minutes break
• Time blocking: Allocate specific time slots for each subject
• Prioritize using Eisenhower Matrix (Urgent/Important)

**Active Learning:**
• Active recall: Test yourself regularly without looking at notes
• Spaced repetition: Review material at increasing intervals
• Teach-back method: Explain concepts to someone else

**Note-Taking:**
• Cornell Note-Taking System
• Mind mapping for complex topics
• Summary sheets for quick revision

**Practice & Testing:**
• Daily problem-solving sessions
• Weekly mock tests
• Error analysis and improvement tracking

**Environment:**
• Dedicated study space
• Minimize distractions
• Good lighting and comfortable seating

**Health & Wellness:**
• Regular breaks and exercise
• Adequate sleep (7-8 hours)
• Proper nutrition and hydration''';
  }

  /// Send a message with context about user's current tasks/focus
  Future<Message> sendMessageWithContext(
      String userMessage, {
        List<String>? currentTasks,
        String? currentFocusSession,
        Map<String, dynamic>? userStats,
      }) async {
    // Enhance the user message with context
    final contextualMessage = _buildContextualMessage(
      userMessage,
      currentTasks: currentTasks,
      currentFocusSession: currentFocusSession,
      userStats: userStats,
    );

    return await sendMessage(contextualMessage);
  }

  /// ENHANCED: Get suggestions with exam-specific options
  List<String> getSuggestions(String lastMessage) {
    if (lastMessage.isEmpty) {
      return [
        'Show me CDS exam timetable',
        'Banking exam day worker schedule',
        'CLAT night owl timetable',
        'HSSC exam overview',
        'Topper study strategies',
        'How can you help me?',
      ];
    }

    // Generate contextual suggestions based on the last message
    final lowerMessage = lastMessage.toLowerCase();

    // Exam-specific suggestions
    if (lowerMessage.contains('cds')) {
      return [
        'CDS day worker timetable',
        'CDS night owl schedule',
        'CDS exam pattern details',
        'SSB preparation tips',
      ];
    }

    if (lowerMessage.contains('banking')) {
      return [
        'Banking exam day worker schedule',
        'Banking night owl timetable',
        'IBPS PO preparation strategy',
        'Banking current affairs tips',
      ];
    }

    if (lowerMessage.contains('clat')) {
      return [
        'CLAT day worker timetable',
        'CLAT night owl schedule',
        'Legal reasoning practice tips',
        'CLAT mock test strategy',
      ];
    }

    if (lowerMessage.contains('hssc') || lowerMessage.contains('haryana')) {
      return [
        'HSSC day worker timetable',
        'HSSC night owl schedule',
        'Haryana GK preparation tips',
        'HSSC exam pattern',
      ];
    }

    // General study suggestions
    if (lowerMessage.contains('task') || lowerMessage.contains('todo')) {
      return [
        'Help me prioritize my tasks',
        'Create a task breakdown',
        'Task management techniques',
        'Show me task management tips',
      ];
    }

    if (lowerMessage.contains('focus') || lowerMessage.contains('concentration')) {
      return [
        'How can I improve my focus?',
        'Pomodoro Technique explanation',
        'Tips for avoiding distractions',
        'Best focus techniques for deep work',
      ];
    }

    if (lowerMessage.contains('time') || lowerMessage.contains('schedule')) {
      return [
        'Help me manage my time better',
        'Create a daily schedule',
        'Time blocking techniques',
        'How to estimate task duration',
      ];
    }

    if (lowerMessage.contains('timetable')) {
      return [
        'Show exam-specific timetables',
        'Day worker vs night owl schedule',
        'Topper study strategies',
        'Custom timetable creation',
      ];
    }

    // Default suggestions for general queries
    return [
      'Tell me more about this',
      'How can I apply this?',
      'What\'s the next step?',
      'Give me specific examples',
      'Show related exam timetables',
    ];
  }

  // ============================================================================
  // EXAM DATA ACCESS METHODS
  // ============================================================================

  /// Get available exam types
  List<ExamType> getAvailableExams() {
    return _examData.keys.toList();
  }

  /// Get exam data for specific exam
  ExamData? getExamData(ExamType examType) {
    return _examData[examType];
  }

  /// Get exam overview
  String? getExamOverview(ExamType examType) {
    return _examData[examType]?.overview;
  }

  /// Get day worker timetable for exam
  String? getDayWorkerTimetable(ExamType examType) {
    return _examData[examType]?.dayWorkerTimetable;
  }

  /// Get night owl timetable for exam
  String? getNightOwlTimetable(ExamType examType) {
    return _examData[examType]?.nightOwlTimetable;
  }

  /// Get exam strategies
  List<String> getExamStrategies(ExamType examType) {
    return _examData[examType]?.strategies ?? [];
  }

  /// Get exam topics
  List<String> getExamTopics(ExamType examType) {
    return _examData[examType]?.keyTopics ?? [];
  }

  /// Search exams by name
  List<ExamType> searchExams(String query) {
    final lowerQuery = query.toLowerCase();
    return _examData.keys.where((examType) {
      final examName = examType.toString().split('.').last.toLowerCase();
      return examName.contains(lowerQuery);
    }).toList();
  }

  // ============================================================================
  // ORIGINAL GROQ CHAT SERVICE METHODS (PRESERVED)
  // ============================================================================

  /// Check if the service is properly configured
  bool get isConfigured => _apiKey.isNotEmpty && _apiKey != 'your_groq_api_key_here';

  /// Ask a question and get a response (ORIGINAL METHOD)
  Future<String> ask(
      String question, {
        String? model,
        int? maxTokens,
        double? temperature,
      }) async {
    if (!isConfigured) {
      throw GroqApiException('API key not configured', 401);
    }

    try {
      final messages = [
        if (_systemPrompt != null && _systemPrompt!.isNotEmpty)
          {
            'role': 'system',
            'content': _systemPrompt!,
          },
        {
          'role': 'user',
          'content': question,
        },
      ];

      final response = await _makeRequest(
        messages: messages,
        model: model ?? _model,
        maxTokens: maxTokens ?? _maxTokens,
        temperature: temperature ?? _temperature,
      );

      return _extractResponseContent(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in Groq chat service: $e');
      }
      rethrow;
    }
  }

  /// Ask with conversation context (ORIGINAL METHOD)
  Future<String> askWithContext(
      String question,
      List<Map<String, String>> conversationHistory, {
        String? model,
        int? maxTokens,
        double? temperature,
      }) async {
    if (!isConfigured) {
      throw GroqApiException('API key not configured', 401);
    }

    try {
      final messages = [
        if (_systemPrompt != null && _systemPrompt!.isNotEmpty)
          {
            'role': 'system',
            'content': _systemPrompt!,
          },
        ...conversationHistory,
        {
          'role': 'user',
          'content': question,
        },
      ];

      final response = await _makeRequest(
        messages: messages,
        model: model ?? _model,
        maxTokens: maxTokens ?? _maxTokens,
        temperature: temperature ?? _temperature,
      );

      return _extractResponseContent(response);
    } catch (e) {
      if (kDebugMode) {
        print('Error in Groq chat service with context: $e');
      }
      rethrow;
    }
  }

  /// Test the connection to Groq API (ORIGINAL METHOD)
  Future<bool> testConnection() async {
    if (!isConfigured) {
      if (kDebugMode) {
        print('⚠️ Groq API key not configured');
      }
      return false;
    }

    try {
      await ask('Hello! Please respond with just "OK" to test the connection.');
      if (kDebugMode) {
        print('✅ Groq connection test successful');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Groq connection test failed: $e');
      }
      return false;
    }
  }

  /// Get available models (ORIGINAL METHOD)
  Future<List<String>> getAvailableModels() async {
    if (!isConfigured) {
      return _getDefaultModels();
    }

    try {
      final url = Uri.parse('$_baseUrl/models');
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final models = data['data'] as List<dynamic>?;
        if (models != null) {
          return models
              .map((model) => model['id'] as String)
              .toList();
        }
      }

      // Return default models if API call fails
      return _getDefaultModels();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting available models: $e');
      }
      // Return default models
      return _getDefaultModels();
    }
  }

  /// Get default models (ORIGINAL METHOD)
  List<String> _getDefaultModels() {
    return [
      'llama3-8b-8192',
      'llama3-70b-8192',
      'mixtral-8x7b-32768',
      'gemma-7b-it',
    ];
  }

  /// Get service status (ENHANCED METHOD)
  Map<String, dynamic> getStatus() {
    return {
      'api_key_configured': isConfigured,
      'base_url': _baseUrl,
      'system_prompt_set': _systemPrompt?.isNotEmpty ?? false,
      'default_model': _model,
      'max_tokens': _maxTokens,
      'temperature': _temperature,
      'initialized': _isInitialized,
      'exam_data_loaded': _examDataLoaded,
      'available_exams': _examData.keys.length,
      'conversation_length': _conversationHistory.length,
    };
  }

  /// Get a user-friendly status message (ENHANCED METHOD)
  String getStatusMessage() {
    if (!isConfigured) {
      return 'API key not configured. Using offline exam data and responses.';
    }

    if (_examDataLoaded) {
      return 'AI assistant ready with Groq API integration and ${_examData.keys.length} exam datasets loaded.';
    }

    return 'AI assistant ready with Groq API integration.';
  }

  // ============================================================================
  // CONVERSATION MANAGEMENT
  // ============================================================================

  /// Get the current conversation history
  List<Message> get conversationHistory => List.unmodifiable(_conversationHistory);

  /// Clear the conversation history
  void clearConversation() {
    _conversationHistory.clear();
    if (kDebugMode) {
      print('ChatbotService: Conversation history cleared');
    }
  }

  /// Get the last message from the bot
  Message? get lastBotMessage {
    for (int i = _conversationHistory.length - 1; i >= 0; i--) {
      if (_conversationHistory[i].sender == MessageSender.bot) {
        return _conversationHistory[i];
      }
    }
    return null;
  }

  /// Get conversation summary
  String getConversationSummary() {
    if (_conversationHistory.isEmpty) return 'No conversation yet';

    final messageCount = _conversationHistory.length;
    final userMessages = _conversationHistory.where((m) => m.sender == MessageSender.user).length;
    final botMessages = _conversationHistory.where((m) => m.sender == MessageSender.bot).length;

    return 'Total messages: $messageCount (User: $userMessages, Bot: $botMessages)';
  }

  // ============================================================================
  // PRODUCTIVITY-SPECIFIC FEATURES (ENHANCED)
  // ============================================================================

  /// Get productivity tips based on user's current situation
  Future<Message> getProductivityTip({
    String? currentFocus,
    int? todaysFocusMinutes,
    List<String>? pendingTasks,
    ExamType? examType,
  }) async {
    String prompt = _buildProductivityTipPrompt(
      currentFocus: currentFocus,
      todaysFocusMinutes: todaysFocusMinutes,
      pendingTasks: pendingTasks,
    );

    // ENHANCED: Add exam-specific context
    if (examType != null && _examData.containsKey(examType)) {
      final examData = _examData[examType]!;
      prompt += '\n\nI am preparing for ${examType.toString().split('.').last.toUpperCase()} exam. ';
      prompt += 'Key topics include: ${examData.keyTopics.join(', ')}. ';
      prompt += 'Please provide exam-specific productivity advice.';
    }

    return await sendMessage(prompt);
  }

  /// Get task prioritization advice (ENHANCED)
  Future<Message> getTaskPrioritizationAdvice(List<String> tasks, {ExamType? examType}) async {
    String prompt = '''
I have these tasks to work on today:
${tasks.map((task) => '- $task').join('\n')}

Can you help me prioritize these tasks using the Eisenhower Matrix (Urgent/Important) and suggest which ones to focus on first?
''';

    // Add exam-specific context
    if (examType != null && _examData.containsKey(examType)) {
      prompt += '\n\nI am preparing for ${examType.toString().split('.').last.toUpperCase()} exam. Please consider exam priorities in your advice.';
    }

    return await sendMessage(prompt);
  }

  /// Get focus session recommendations (ENHANCED)
  Future<Message> getFocusSessionRecommendation({
    required int plannedDuration,
    String? taskType,
    int? currentStreakDays,
    ExamType? examType,
  }) async {
    String prompt = '''
I'm planning a ${plannedDuration}-minute focus session${taskType != null ? ' for $taskType' : ''}. ${currentStreakDays != null ? 'I\'ve been maintaining a $currentStreakDays-day focus streak.' : ''}

Can you suggest:
1. The best technique to use (Pomodoro, Deep Work, etc.)
2. How to prepare for maximum productivity
3. Tips to maintain focus during the session
''';

    // Add exam-specific recommendations
    if (examType != null && _examData.containsKey(examType)) {
      final examData = _examData[examType]!;
      prompt += '\n\nI am preparing for ${examType.toString().split('.').last.toUpperCase()} exam. ';
      prompt += 'My focus areas should include: ${examData.keyTopics.take(3).join(', ')}. ';
      prompt += 'Please provide exam-specific focus session advice.';
    }

    return await sendMessage(prompt);
  }

  /// ADDED: Get exam-specific study plan
  Future<Message> getExamStudyPlan({
    required ExamType examType,
    required int daysUntilExam,
    required int dailyStudyHours,
    ScheduleType? preferredSchedule,
  }) async {
    if (!_examData.containsKey(examType)) {
      return Message(
        content: 'Sorry, I don\'t have specific data for this exam yet. Please try a general study plan request.',
        sender: MessageSender.bot,
      );
    }

    final examData = _examData[examType]!;
    final examName = examType.toString().split('.').last.toUpperCase();

    String prompt = '''
Please create a detailed study plan for ${examName} exam with these details:
- Days until exam: $daysUntilExam
- Daily study hours available: $dailyStudyHours
- Preferred schedule: ${preferredSchedule?.toString().split('.').last ?? 'flexible'}

Key topics to cover: ${examData.keyTopics.join(', ')}

Strategies to incorporate: ${examData.strategies.join(', ')}

Please provide:
1. Week-wise breakdown
2. Subject-wise time allocation
3. Revision schedule
4. Mock test schedule
5. Final week strategy
''';

    return await sendMessage(prompt);
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Make HTTP request to Groq API (ORIGINAL METHOD)
  Future<Map<String, dynamic>> _makeRequest({
    required List<Map<String, dynamic>> messages,
    required String model,
    required int maxTokens,
    required double temperature,
  }) async {
    final url = Uri.parse('$_baseUrl/chat/completions');

    final requestBody = {
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': false,
    };

    if (kDebugMode) {
      print('🚀 Making Groq API request...');
      print('Model: $model');
      print('Messages count: ${messages.length}');
    }

    try {
      final response = await _httpClient.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw GroqApiException('Request timed out after 30 seconds', 408);
        },
      );

      if (kDebugMode) {
        print('📡 Groq API response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;

        if (kDebugMode) {
          final usage = responseData['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            print('📊 Token usage - Prompt: ${usage['prompt_tokens']}, Completion: ${usage['completion_tokens']}, Total: ${usage['total_tokens']}');
          }
        }

        return responseData;
      } else {
        final errorBody = response.body;
        if (kDebugMode) {
          print('❌ Groq API error: ${response.statusCode}');
          print('Error body: $errorBody');
        }

        // Parse error message if available
        try {
          final errorData = jsonDecode(errorBody) as Map<String, dynamic>;
          final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
          throw GroqApiException(
            'Groq API error (${response.statusCode}): $errorMessage',
            response.statusCode,
          );
        } catch (e) {
          if (e is GroqApiException) rethrow;
          throw GroqApiException(
            'Groq API error (${response.statusCode}): $errorBody',
            response.statusCode,
          );
        }
      }
    } on http.ClientException catch (e) {
      throw GroqApiException('Network error: ${e.message}', 0);
    } catch (e) {
      if (e is GroqApiException) rethrow;
      throw GroqApiException('Unexpected error: $e', 0);
    }
  }

  /// Extract response content from API response (ORIGINAL METHOD)
  String _extractResponseContent(Map<String, dynamic> response) {
    try {
      final choices = response['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw GroqApiException('No choices in response', 0);
      }

      final firstChoice = choices[0] as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;
      if (message == null) {
        throw GroqApiException('No message in choice', 0);
      }

      final content = message['content'] as String?;
      if (content == null || content.isEmpty) {
        throw GroqApiException('Empty content in message', 0);
      }

      return content.trim();
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting response content: $e');
        print('Response structure: ${jsonEncode(response)}');
      }
      if (e is GroqApiException) rethrow;
      throw GroqApiException('Failed to extract response content: $e', 0);
    }
  }

  /// Call the Groq API with the prepared messages
  Future<String> _callGroqAPI(List<Map<String, String>> messages) async {
    final url = Uri.parse('$_baseUrl/chat/completions');

    final requestBody = {
      'model': _model,
      'messages': messages,
      'max_tokens': _maxTokens,
      'temperature': _temperature,
      'stream': false,
    };

    if (kDebugMode) {
      print('ChatbotService: Making API request to $url');
    }

    final response = await _httpClient
        .post(
      url,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    )
        .timeout(_timeoutDuration);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['choices'] != null &&
          responseData['choices'].isNotEmpty &&
          responseData['choices'][0]['message'] != null) {

        final content = responseData['choices'][0]['message']['content'];
        return content?.toString().trim() ?? 'Sorry, I received an empty response.';
      } else {
        throw ChatbotException('Invalid API response format');
      }
    } else {
      final errorMessage = _parseErrorResponse(response);
      throw ChatbotException('API request failed: $errorMessage');
    }
  }

  /// Prepare messages for the API call
  List<Map<String, String>> _prepareMessages() {
    final messages = <Map<String, String>>[];

    // Add system prompt if available
    if (_systemPrompt != null && _systemPrompt!.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': _systemPrompt!,
      });
    }

    // Add conversation history (keep last 10 messages to avoid token limits)
    final recentHistory = _conversationHistory.length > 10
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;

    for (final message in recentHistory) {
      messages.add({
        'role': message.sender == MessageSender.user ? 'user' : 'assistant',
        'content': message.content,
      });
    }

    return messages;
  }

  /// Build a contextual message with user data
  String _buildContextualMessage(
      String userMessage, {
        List<String>? currentTasks,
        String? currentFocusSession,
        Map<String, dynamic>? userStats,
      }) {
    final buffer = StringBuffer(userMessage);

    if (currentTasks != null && currentTasks.isNotEmpty) {
      buffer.write('\n\nCurrent tasks:');
      for (final task in currentTasks) {
        buffer.write('\n- $task');
      }
    }

    if (currentFocusSession != null) {
      buffer.write('\n\nCurrent focus session: $currentFocusSession');
    }

    if (userStats != null && userStats.isNotEmpty) {
      buffer.write('\n\nMy productivity stats:');
      userStats.forEach((key, value) {
        buffer.write('\n- $key: $value');
      });
    }

    return buffer.toString();
  }

  /// Build a productivity tip prompt
  String _buildProductivityTipPrompt({
    String? currentFocus,
    int? todaysFocusMinutes,
    List<String>? pendingTasks,
  }) {
    final buffer = StringBuffer('Give me a personalized productivity tip');

    if (currentFocus != null) {
      buffer.write(' for my current focus area: $currentFocus');
    }

    if (todaysFocusMinutes != null) {
      buffer.write('. I\'ve focused for $todaysFocusMinutes minutes today');
    }

    if (pendingTasks != null && pendingTasks.isNotEmpty) {
      buffer.write('. I have ${pendingTasks.length} pending tasks');
    }

    buffer.write('. Make it specific and actionable.');

    return buffer.toString();
  }

  /// Get default system prompt for productivity assistant (ENHANCED)
  String _getDefaultSystemPrompt() {
    return '''You are a helpful productivity and exam preparation assistant. You specialize in:

- Task organization and prioritization using the Eisenhower Matrix
- Focus techniques like the Pomodoro Technique and Deep Work
- Time management strategies and productivity systems
- Habit formation and goal achievement
- Work-life balance and stress management
- Motivation and accountability
- Exam preparation strategies and timetables
- Study plans for various competitive exams

You have access to detailed timetables and strategies for exams like CDS, NDA, Banking, CLAT, CA, HSSC, JEE, NEET, UPSC, CAT, and SSC CGL.

Guidelines for your responses:
- Keep responses concise, practical, and actionable
- Use a friendly, encouraging, and supportive tone
- Provide specific steps users can take immediately
- Reference proven productivity techniques and frameworks
- Ask clarifying questions when needed to give better advice
- Celebrate user achievements and progress
- Offer alternative approaches when one method doesn't work
- For exam queries, provide specific timetables and strategies
- Focus on helping users build sustainable study and productivity habits

Focus on helping users build sustainable productivity habits rather than quick fixes.''';
  }

  /// Parse error response from API
  String _parseErrorResponse(http.Response response) {
    try {
      final errorData = json.decode(response.body);
      if (errorData['error'] != null) {
        final error = errorData['error'];
        if (error is Map && error['message'] != null) {
          return error['message'].toString();
        } else if (error is String) {
          return error;
        }
      }
    } catch (e) {
      // If we can't parse the error, return a generic message
    }

    return 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
  }

  /// Get user-friendly error response message
  String _getErrorResponseMessage(dynamic error) {
    if (error is ChatbotException) {
      return 'I\'m having trouble right now: ${error.message}. Please try again in a moment.';
    } else if (error is TimeoutException) {
      return 'I\'m taking longer than usual to respond. Please try asking your question again.';
    } else if (error.toString().contains('network') ||
        error.toString().contains('connection')) {
      return 'I\'m having trouble connecting right now. Please check your internet connection and try again.';
    } else {
      return 'I encountered an unexpected issue. Please try rephrasing your question or try again later.';
    }
  }

  /// Validate URL format
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  /// Dispose of resources
  void dispose() {
    _httpClient.close();
    _conversationHistory.clear();
    _examData.clear();
    _isInitialized = false;
    _examDataLoaded = false;

    if (kDebugMode) {
      print('ChatbotService: Disposed');
    }
  }
}

// ============================================================================
// EXCEPTION CLASSES (ORIGINAL AND NEW)
// ============================================================================

/// Exception for chatbot-related errors
class ChatbotException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const ChatbotException(
      this.message, {
        this.code,
        this.originalError,
      });

  @override
  String toString() {
    final buffer = StringBuffer('ChatbotException: $message');
    if (code != null) {
      buffer.write(' (Code: $code)');
    }
    return buffer.toString();
  }
}

/// Custom exception for Groq API errors (ORIGINAL CLASS)
class GroqApiException implements Exception {
  final String message;
  final int statusCode;

  GroqApiException(this.message, this.statusCode);

  @override
  String toString() => 'GroqApiException: $message (Status: $statusCode)';

  /// Check if this is a network-related error
  bool get isNetworkError => statusCode == 0 || statusCode == 408;

  /// Check if this is an authentication error
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Check if this is a rate limit error
  bool get isRateLimitError => statusCode == 429;

  /// Check if this is a server error
  bool get isServerError => statusCode >= 500;

  /// Get a user-friendly error message
  String get userFriendlyMessage {
    if (isNetworkError) {
      return 'Network connection issue. Please check your internet connection.';
    } else if (isAuthError) {
      return 'API authentication failed. Please check your API key configuration.';
    } else if (isRateLimitError) {
      return 'Too many requests. Please wait a moment before trying again.';
    } else if (isServerError) {
      return 'Server is temporarily unavailable. Please try again later.';
    } else {
      return 'An unexpected error occurred. Using offline responses.';
    }
  }
}

// ============================================================================
// UTILITY EXTENSIONS
// ============================================================================

/// Extension on ChatbotService for additional convenience methods
extension ChatbotServiceExtensions on ChatbotService {
  /// Check if the service is ready to use
  bool get isReady => _isInitialized;

  /// Get the current conversation length
  int get conversationLength => conversationHistory.length;

  /// Check if there's an ongoing conversation
  bool get hasConversation => conversationHistory.isNotEmpty;

  /// Get the last user message
  Message? get lastUserMessage {
    for (int i = conversationHistory.length - 1; i >= 0; i--) {
      if (conversationHistory[i].sender == MessageSender.user) {
        return conversationHistory[i];
      }
    }
    return null;
  }

  /// Get API base URL
  String get baseUrl => _baseUrl;

  /// Get default model being used
  String get defaultModel => _model;

  /// Get max tokens setting
  int get maxTokens => ChatbotService._maxTokens;

  /// Get temperature setting
  double get temperature => ChatbotService._temperature;

  /// Check if exam data is loaded
  bool get hasExamData => _examDataLoaded;

  /// Get exam data summary
  Map<String, dynamic> get examDataSummary {
    return {
      'loaded': _examDataLoaded,
      'examCount': _examData.length,
      'availableExams': _examData.keys.map((e) => e.toString().split('.').last).toList(),
    };
  }
}

/// Extension for ExamType enum
extension ExamTypeExtensions on ExamType {
  /// Get display name for exam type
  String get displayName {
    switch (this) {
      case ExamType.cds:
        return 'CDS (Combined Defence Services)';
      case ExamType.nda:
        return 'NDA (National Defence Academy)';
      case ExamType.banking:
        return 'Banking Exams (IBPS/SBI)';
      case ExamType.clat:
        return 'CLAT (Common Law Admission Test)';
      case ExamType.ca:
        return 'CA (Chartered Accountant)';
      case ExamType.hssc:
        return 'HSSC (Haryana Staff Selection Commission)';
      case ExamType.jee:
        return 'JEE (Joint Entrance Examination)';
      case ExamType.neet:
        return 'NEET (National Eligibility cum Entrance Test)';
      case ExamType.upsc:
        return 'UPSC (Union Public Service Commission)';
      case ExamType.cat:
        return 'CAT (Common Admission Test)';
      case ExamType.sscCgl:
        return 'SSC CGL (Staff Selection Commission Combined Graduate Level)';
    }
  }

  /// Get exam category
  String get category {
    switch (this) {
      case ExamType.cds:
      case ExamType.nda:
        return 'Defence';
      case ExamType.banking:
        return 'Banking & Finance';
      case ExamType.clat:
        return 'Law';
      case ExamType.ca:
        return 'Accounting & Finance';
      case ExamType.hssc:
      case ExamType.sscCgl:
        return 'Government Jobs';
      case ExamType.jee:
      case ExamType.neet:
        return 'Engineering & Medical';
      case ExamType.upsc:
        return 'Civil Services';
      case ExamType.cat:
        return 'Management';
    }
  }

  /// Get typical duration in months
  int get typicalPreparationMonths {
    switch (this) {
      case ExamType.cds:
      case ExamType.nda:
        return 6;
      case ExamType.banking:
      case ExamType.hssc:
      case ExamType.sscCgl:
        return 4;
      case ExamType.clat:
        return 12;
      case ExamType.ca:
        return 18;
      case ExamType.jee:
      case ExamType.neet:
        return 24;
      case ExamType.upsc:
        return 18;
      case ExamType.cat:
        return 8;
    }
  }
}

/// Extension for ScheduleType enum
extension ScheduleTypeExtensions on ScheduleType {
  /// Get display name for schedule type
  String get displayName {
    switch (this) {
      case ScheduleType.dayWorker:
        return 'Day Worker (Morning Person)';
      case ScheduleType.nightOwl:
        return 'Night Owl (Evening Person)';
      case ScheduleType.overview:
        return 'Overview & Information';
    }
  }

  /// Get description
  String get description {
    switch (this) {
      case ScheduleType.dayWorker:
        return 'Early morning start, peak productivity in morning hours';
      case ScheduleType.nightOwl:
        return 'Late start, peak productivity in evening/night hours';
      case ScheduleType.overview:
        return 'General information and exam pattern details';
    }
  }

  /// Get recommended start time
  String get recommendedStartTime {
    switch (this) {
      case ScheduleType.dayWorker:
        return '6:00 AM';
      case ScheduleType.nightOwl:
        return '10:00 AM';
      case ScheduleType.overview:
        return 'Flexible';
    }
  }

  /// Get peak study hours
  String get peakStudyHours {
    switch (this) {
      case ScheduleType.dayWorker:
        return '8:00 AM - 12:00 PM';
      case ScheduleType.nightOwl:
        return '8:00 PM - 12:00 AM';
      case ScheduleType.overview:
        return 'Varies';
    }
  }
}

