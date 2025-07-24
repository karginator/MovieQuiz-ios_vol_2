import UIKit

struct GameResult {
    let correct: Int // Кол-во правильных ответов
    let total: Int // Колв-во вопросов в квизе
    let date: Date // Дата, когда пользователь сыграл
    
    // Метод сравнивает текущий GameResult с каким-то другим
        func isBetterThan(_ another: GameResult) -> Bool { correct >= another.correct }
}
