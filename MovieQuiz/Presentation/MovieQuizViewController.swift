import UIKit

final class MovieQuizViewController: UIViewController {
    
    // MARK: - IB Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var yesButton: UIButton!
    @IBOutlet weak var noButton: UIButton!
    
    // MARK: - Private Properties
    private let storage: UserDefaults = .standard
    private var currentQuestionIndex = 0 // Индекс текущего вопроса
    private var correctAnswers = 0 // Кол-во правильных ответов
    private let questionsAmount: Int = 10 // Кол-во вопросов в кивзе
    private var currentQuestion: QuizQuestion? // Текущий вопрос
    private var questionFactory: QuestionFactoryProtocol? // Фабрика вопросов, к ней будем обращаться, чтобы получить вопрос для квиза
    private var alertPresenter: AlertPresenter? // Будет презентовать алерт
    private var statisticService: StatisticServiceProtocol? // С его помощью собирается статистика
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
//        cleanStore()
        let questionFactory = QuestionFactory()
//        questionFactory.setup(delegate: self)
        questionFactory.delegate = self
        self.questionFactory = questionFactory
        
        let alertPresenter = AlertPresenter()
        alertPresenter.viewController = self
        self.alertPresenter = alertPresenter
        
        self.questionFactory?.requestNextQuestion()
        
        statisticService = StatisticService()
    }
    
    // MARK: - IB Actions
    @IBAction func yesButtonClicked(_ sender: Any) {
        let givenAnswer = true
        guard let currentQuestion else { return }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer == givenAnswer)
    }
    
    @IBAction func noButtonClicked(_ sender: Any) {
        let givenAnswer = false
        guard let currentQuestion else { return }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer == givenAnswer)
    }
    
    // MARK: - Private Methods
    // Метод конвертирует QuizQuestion в QuizStepViewModel, то есть вопрос как сущность в вопрос для квиза
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex+1)/\(questionsAmount)")
    }
    
    // Метод берет данные из вью модели, QuizStepViewModel и отрисовывает их на экран
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        imageView.layer.cornerRadius = 20
    }
    
    // Метод красит рамку, то есть в целом отображает результат ответа
    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.borderColor = isCorrect ? #colorLiteral(red: 0.3764705882, green: 0.7607843137, blue: 0.5568627451, alpha: 1) : #colorLiteral(red: 0.9607843137, green: 0.4196078431, blue: 0.4235294118, alpha: 1)
        
        if isCorrect { correctAnswers += 1 }
        
        isEnabledButton(isTrue: false)
        
        // Поскольку showAnswerResult показывается после ответа пользователя, то даем еще 1 секунду, чтобы разглядел ответ, то есть посмотрел на цвет рамки, и далее показываем следующий вопрос или резульятат квиза и убираем подкраску рамки
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.showNextQuestionOrResult()
            self.zeroBorderWidth()
            self.isEnabledButton(isTrue: true)
        }
    }
    
    // Метод показывает следующий вопрос или результат, если текущий вопрос был последним
    private func showNextQuestionOrResult() {
        if currentQuestionIndex == questionsAmount - 1 {
            
            let currentGame = GameResult(
                correct: correctAnswers,
                total: questionsAmount,
                date: Date())
            
            guard let statisticService = statisticService else { return }
            statisticService.store(correct: currentGame.correct, total: currentGame.total)
            let countQuiz = storage.integer(forKey: Keys.gamesCount.rawValue)
            
            let message = """
                Ваш результат: \(correctAnswers)/\(questionsAmount)
                Количество сыгранных квизов: \(countQuiz)
                Рекорд: \(statisticService.bestGame.correct)/\(questionsAmount) (\(statisticService.bestGame.date.dateTimeString))
                Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
                
                """
            
            self.alertPresenter?.showAlert(
                alertModel: AlertModel(
                    title: "Этот раунд окончен!",
                    message: message,
                    buttonText: "Сыграть еще раз") { [weak self] in
                        guard let self else { return }
                        restartGame()
                    }
            )
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }
    
    // Метод обнуляет рамку, чтобы она не была подкрашена до ответа пользователя
    private func zeroBorderWidth() {
        imageView.layer.borderWidth = 0
    }
    
    // Метод блокирует/разблокирует нажание кнопок для ответа
    private func isEnabledButton(isTrue: Bool) {
        noButton.isEnabled = isTrue
        yesButton.isEnabled = isTrue
    }
    
    // Рестарт квиза
    private func restartGame() {
        currentQuestionIndex = 0
        correctAnswers = 0
        questionFactory?.requestNextQuestion()
    }
}

// MARK: - Extension QuestionFactoryDelegate
extension MovieQuizViewController: QuestionFactoryDelegate {
    
    // Метод который будет вызывать когда вопрос будет готов к показу в методе requestNextQuestion()
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question else { return }
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
}

/*
 Mock-данные
 
 
 Картинка: The Godfather
 Настоящий рейтинг: 9,2
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Dark Knight
 Настоящий рейтинг: 9
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Kill Bill
 Настоящий рейтинг: 8,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Avengers
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Deadpool
 Настоящий рейтинг: 8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: The Green Knight
 Настоящий рейтинг: 6,6
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: ДА
 
 
 Картинка: Old
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: The Ice Age Adventures of Buck Wild
 Настоящий рейтинг: 4,3
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: Tesla
 Настоящий рейтинг: 5,1
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 
 
 Картинка: Vivarium
 Настоящий рейтинг: 5,8
 Вопрос: Рейтинг этого фильма больше чем 6?
 Ответ: НЕТ
 */
