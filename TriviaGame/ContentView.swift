//
//  ContentView.swift
//  TriviaGame
//
//  Created by Samuel Lopez on 3/28/25.
//

import SwiftUI

// MARK: - App Screen States
enum AppScreen {
    case options
    case quiz
    case results(score: Int)
}

// MARK: - Difficulty Enum
enum Difficulty: String, CaseIterable, Identifiable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var id: String { self.rawValue }
}

// MARK: - QuestionType Enum
enum QuestionType: String, CaseIterable, Identifiable {
    case multiple = "multiple"
    case boolean = "boolean"
    
    var id: String { self.rawValue }
}

// MARK: - TriviaQuestion Model
struct TriviaQuestion: Identifiable {
    let id = UUID()
    let question: String
    let correctAnswer: String
    let incorrectAnswers: [String]
    
    /// Store the shuffled answers in a property so they don't change after creation
    let allAnswers: [String]
    
    init(question: String, correctAnswer: String, incorrectAnswers: [String]) {
        self.question = question
        self.correctAnswer = correctAnswer
        self.incorrectAnswers = incorrectAnswers
        // Shuffle once and store
        self.allAnswers = (incorrectAnswers + [correctAnswer]).shuffled()
    }
}

// MARK: - API Response Models
struct TriviaAPIResponse: Decodable {
    let response_code: Int
    let results: [APIDecodedQuestion]
}

struct APIDecodedQuestion: Decodable {
    let category: String
    let type: String
    let difficulty: String
    let question: String
    let correct_answer: String
    let incorrect_answers: [String]
}

// MARK: - ContentView
struct ContentView: View {
    
    // Controls which screen we see
    @State private var currentScreen: AppScreen = .options
    
    // Trivia Options
    @State private var numberOfQuestions: Int = 5
    
    // Instead of storing Difficulty directly, we store a slider index:
    // 0 -> Easy, 1 -> Medium, 2 -> Hard
    @State private var difficultyIndex: Double = 1.0
    
    // We’ll still keep a "selectedQuestionType" but make it a menu instead of segmented control
    @State private var selectedQuestionType: QuestionType = .multiple
    
    // We'll store a "selectedCategory" and let the user pick from a menu
    @State private var selectedCategory: Int = 9  // 9 = General Knowledge by default
    
    // A new slider for “Timer Duration”
    @State private var timerDuration: Int = 30
    
    // Fetched questions
    @State private var questions: [TriviaQuestion] = []
    
    // Tracks user’s chosen answers, keyed by question index
    @State private var selectedAnswers: [Int: String] = [:]
    
    // A computed property to map the difficultyIndex to a Difficulty enum
    private var currentDifficulty: Difficulty {
        switch Int(difficultyIndex) {
        case 0: return .easy
        case 1: return .medium
        case 2: return .hard
        default: return .medium
        }
    }
    
    // A string to show in the UI
    private var difficultyString: String {
        switch currentDifficulty {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }
    
    var body: some View {
        switch currentScreen {
        case .options:
            optionsScreen
        case .quiz:
            quizScreen
        case .results(let score):
            resultsScreen(score: score)
        }
    }
    
    // MARK: - Options Screen (Updated UI)
    private var optionsScreen: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                Text("Trivia Game")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 20)
                
                // Number of Questions (Slider)
                HStack {
                    Text("Number of Questions: \(numberOfQuestions)")
                    Spacer()
                }
                .padding(.horizontal)
                
                Slider(
                    value: Binding(
                        get: { Double(numberOfQuestions) },
                        set: { numberOfQuestions = Int($0) }
                    ),
                    in: 1...50,
                    step: 1
                )
                .padding(.horizontal)
                
                // Category
                HStack {
                    Text("Select Category")
                    Spacer()
                    Picker("Category", selection: $selectedCategory) {
                        Text("Any Category").tag(0)
                        Text("General (9)").tag(9)
                        Text("Sports (21)").tag(21)
                        Text("History (23)").tag(23)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)
                
                // Difficulty slider
                HStack {
                    Text("Difficulty: \(difficultyString)")
                    Spacer()
                }
                .padding(.horizontal)
                Slider(value: $difficultyIndex, in: 0...2, step: 1)
                    .padding(.horizontal)
                
                // Question Type
                HStack {
                    Text("Select Type")
                    Spacer()
                    Picker("Question Type", selection: $selectedQuestionType) {
                        Text("Multiple").tag(QuestionType.multiple)
                        Text("True / False").tag(QuestionType.boolean)
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding(.horizontal)
                
                // Timer Duration slider (if you need it)
                HStack {
                    Text("Timer Duration: \(timerDuration) seconds")
                    Spacer()
                }
                .padding(.horizontal)
                Slider(value: Binding(
                    get: { Double(timerDuration) },
                    set: { timerDuration = Int($0) }
                ), in: 10...60, step: 5)
                .padding(.horizontal)
                
                // Start Trivia Button
                Button(action: {
                    fetchTriviaQuestions()
                }) {
                    Text("Start Trivia")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }

    
    // MARK: - Quiz Screen
    private var quizScreen: some View {
        NavigationView {
            VStack(spacing: 8) {
                Text("Quiz Time!")
                    .font(.largeTitle)
                    .padding(.top)
                
                // Display the selected timer duration
                Text("You have \(timerDuration) seconds")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Existing List of questions
                List {
                    ForEach(questions.indices, id: \.self) { index in
                        let question = questions[index]
                        
                        Section(header: Text(question.question)) {
                            ForEach(question.allAnswers, id: \.self) { answer in
                                HStack {
                                    Text(answer)
                                    Spacer()
                                    // Mark if selected
                                    if selectedAnswers[index] == answer {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedAnswers[index] = answer
                                }
                            }
                        }
                    }
                }
                
                Button("Submit Answers") {
                    let score = calculateScore()
                    currentScreen = .results(score: score)
                }
                .padding()
                .background(Color.green.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.bottom)
            }
            .navigationTitle("Trivia")
        }
    }

    
    // MARK: - Results Screen
    private func resultsScreen(score: Int) -> some View {
        // 1) Build an array of missed questions for quick display.
        //    We'll include the question text, user's answer, and correct answer.
        let missedQuestions = questions.enumerated().compactMap { (index, question) -> (question: String, userAnswer: String, correctAnswer: String)? in
            
            // If user never selected an answer, we'll display "No answer"
            let userAnswer = selectedAnswers[index] ?? "No answer"
            
            // If user's answer doesn't match the correct one, it's "missed."
            if userAnswer != question.correctAnswer {
                return (question.question, userAnswer, question.correctAnswer)
            } else {
                return nil
            }
        }
        
        return VStack(spacing: 20) {
            Text("Results")
                .font(.largeTitle)
                .padding(.top, 40)
            
            Text("You scored \(score) out of \(questions.count)!")
                .font(.title2)
            
            // 2) If there are missed questions, display them.
            if !missedQuestions.isEmpty {
                Text("Missed Questions")
                    .font(.headline)
                    .padding(.top, 10)
                
                // A simple List to show each missed question
                List(missedQuestions.indices, id: \.self) { i in
                    let missed = missedQuestions[i]
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question:")
                            .fontWeight(.bold)
                        Text(missed.question)
                        
                        Text("Your Answer:")
                            .fontWeight(.bold)
                        Text(missed.userAnswer)
                        
                        Text("Correct Answer:")
                            .fontWeight(.bold)
                        Text(missed.correctAnswer)
                    }
                    .padding(.vertical, 4)
                }
                
            } else {
                // If no missed questions, user got all correct!
                Text("Perfect! You got everything correct.")
                    .font(.body)
                    .padding(.top, 10)
            }
            
            Button("Play Again") {
                // Reset everything
                selectedAnswers.removeAll()
                questions.removeAll()
                currentScreen = .options
            }
            .padding()
            .background(Color.blue.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(8)
            
            Spacer()
        }
    }

    
    // MARK: - Networking: Fetch Trivia Questions
    private func fetchTriviaQuestions() {
        let baseURL = "https://opentdb.com/api.php"
        
        // Convert our difficultyIndex to the actual string
        let difficultyParam = currentDifficulty.rawValue
        
        // Build the request
        let urlString = "\(baseURL)?amount=\(numberOfQuestions)" +
                        (selectedCategory != 0 ? "&category=\(selectedCategory)" : "") +
                        "&difficulty=\(difficultyParam)" +
                        "&type=\(selectedQuestionType.rawValue)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data {
                do {
                    let decoded = try JSONDecoder().decode(TriviaAPIResponse.self, from: data)
                    
                    // Decode HTML right away
                    let newQuestions: [TriviaQuestion] = decoded.results.map { item in
                        TriviaQuestion(
                            question: decodeHTML(item.question),
                            correctAnswer: decodeHTML(item.correct_answer),
                            incorrectAnswers: item.incorrect_answers.map { decodeHTML($0) }
                        )
                    }
                    
                    DispatchQueue.main.async {
                        self.questions = newQuestions
                        self.selectedAnswers = [:]
                        self.currentScreen = .quiz
                    }
                } catch {
                    print("Decoding error:", error)
                }
            } else if let error = error {
                print("Network error:", error.localizedDescription)
            }
        }.resume()
    }
    
    // MARK: - Score Calculation
    private func calculateScore() -> Int {
        var totalCorrect = 0
        for (index, question) in questions.enumerated() {
            if selectedAnswers[index] == question.correctAnswer {
                totalCorrect += 1
            }
        }
        return totalCorrect
    }
}

// MARK: - HTML Decode Helper
private func decodeHTML(_ text: String) -> String {
    guard let data = text.data(using: .utf8) else { return text }
    do {
        let attributedString = try NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
        return attributedString.string
    } catch {
        print("HTML decoding error:", error)
        return text
    }
}
