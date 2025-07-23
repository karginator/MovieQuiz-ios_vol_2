import UIKit

struct AlertModel {
    let title: String // Заголовок алерта
    let message: String // Текст алерта
    let buttonText: String // Текст на кнопке
    let compilition: () -> Void // Замыкание для действия по кнопке
}
