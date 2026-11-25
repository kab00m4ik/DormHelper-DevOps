workspace "DormHelper" "Інформаційна система обліку та обробки заявок на технічне обслуговування і ремонт у студентському гуртожитку" {

    model {
        student = person "Студент" "Подає заявки на ремонт, стежить за статусом, оцінює якість робіт"
        staff = person "Майстер / Комендант" "Опрацьовує заявки, призначає виконавців, оновлює статус і дивиться звіти"

        uniSso = softwareSystem "Університетський SSO / Auth" "Перевірка облікового запису та ролей користувачів" "External"
        notifySys = softwareSystem "Сервіс сповіщень (Telegram API / SMTP)" "Надсилання сповіщень про зміну статусів та аварійні заявки" "External"
        s3 = softwareSystem "Object Storage (MinIO / S3)" "Зберігає фотографії поломок та фотозвіти виконаних робіт" "External"

        dormHelper = softwareSystem "Система DormHelper" "Інформаційна система обліку та обробки заявок на ТО і ремонт у гуртожитку" {
            spa = container "Single-Page Application" "Інтерфейс подання заявок, реєстру звернень, кабінету майстра та аналітики" "React / TypeScript"
            api = container "Core Backend API" "Обробляє бізнес-логіку заявок, ролі (RBAC), валідацію, історію статусів та Outbox" "ASP.NET Core / C#"
            worker = container "Notification & Report Worker" "Асинхронно обробляє події зміни статусів, надсилає сповіщення та формує звіти" "Background Worker"
            db = container "Relational Database" "Зберігає заявки, історію змін, користувачів, кімнати/корпуси та outbox-події" "PostgreSQL"
            cache = container "In-Memory Cache & Queue" "Кешує довідники приміщень/категорій, лімітує запити та тримає чергу задач" "Redis"
        }

        student -> dormHelper "Створює заявки, переглядає історію та оцінює ремонт" "HTTPS"
        staff -> dormHelper "Керує пріоритетами, призначає майстрів, оновлює статуси та звіти" "HTTPS"
        dormHelper -> uniSso "Автентифікує користувачів" "OIDC / OAuth 2.0"
        dormHelper -> notifySys "Надсилає сповіщення користувачам" "HTTPS / SMTP"

        student -> spa "Відкриває портал та подає заявки" "HTTPS"
        staff -> spa "Керує заявками та переглядає звіти" "HTTPS"
        spa -> api "Викликає REST API" "JSON / HTTPS"
        spa -> s3 "Завантажує та переглядає фото за Pre-signed URLs" "HTTPS"

        api -> db "Читає та записує дані заявок і Outbox" "TCP / SQL"
        api -> cache "Кешує довідники та ставить задачі в чергу" "TCP"
        api -> s3 "Генерує Pre-signed URLs для фото" "S3 API"
        api -> uniSso "Перевіряє токени авторизації" "HTTPS"

        worker -> cache "Бере задачі на відправку сповіщень та звіти" "TCP"
        worker -> db "Читає дані заявок та оновлює статус доставки" "TCP / SQL"
        worker -> notifySys "Надсилає сповіщення користувачам" "HTTPS / SMTP"
    }

    views {
        systemContext dormHelper "SystemContext" {
            include *
            autoLayout
        }

        container dormHelper "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
        }
    }
}
